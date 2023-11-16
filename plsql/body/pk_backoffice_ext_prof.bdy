/*-- Last Change Revision: $Rev: 2026779 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:52 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_backoffice_ext_prof IS

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
    * Returns Number of External Professionals linked to an Insitution
    *
    * @param i_lang                  Language id
    * @param i_id_institution        Institution identifier
    * @param i_id_ext_prof_to        Professional Take over ID
    * @param i_search                Search
    * @param o_ext_prof_count        External professionals count
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_prof_list_count
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_ext_prof_to IN professional.id_professional%TYPE,
        i_search         IN VARCHAR2,
        o_ext_prof_count OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_category professional_field_data.value%TYPE;
        l_id_market   market.id_market%TYPE;
    
    BEGIN
    
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        g_error := 'GET EXT_PROF_COUNT CURSOR';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_LIST_COUNT ' || g_error);
    
        IF i_id_ext_prof_to IS NULL
        THEN
        
            IF i_search IS NULL
            THEN
            
                SELECT COUNT(p.id_professional)
                  INTO o_ext_prof_count
                  FROM prof_institution pi, professional p
                 WHERE pi.flg_external = pk_alert_constant.get_yes
                   AND pi.flg_state = g_ext_prof_active
                   AND pi.dt_end_tstz IS NULL
                   AND pi.id_institution = i_id_institution
                   AND pi.id_professional = p.id_professional;
            
            ELSE
            
                SELECT COUNT(p.id_professional)
                  INTO o_ext_prof_count
                  FROM prof_institution pi, professional p
                 WHERE pi.flg_external = pk_alert_constant.get_yes
                   AND pi.flg_state = g_ext_prof_active
                   AND pi.dt_end_tstz IS NULL
                   AND pi.id_institution = i_id_institution
                   AND pi.id_professional = p.id_professional
                   AND translate(upper(p.name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%';
            
            END IF;
        
        ELSE
        
            SELECT nvl((SELECT pfd.value
                         FROM professional_field_data pfd, field_market fm
                        WHERE pfd.id_professional = i_id_ext_prof_to
                          AND pfd.id_field_market = fm.id_field_market
                          AND fm.id_field = 43
                          AND fm.id_market = l_id_market
                          AND pfd.id_institution = 0),
                       NULL)
              INTO l_id_category
              FROM dual;
        
            IF i_search IS NULL
            THEN
                SELECT COUNT(p.id_professional)
                  INTO o_ext_prof_count
                  FROM prof_institution pi, professional p
                 WHERE pi.flg_external = pk_alert_constant.get_yes
                   AND pi.flg_state = g_ext_prof_active
                   AND pi.dt_end_tstz IS NULL
                   AND pi.id_institution = i_id_institution
                   AND pi.id_professional = p.id_professional
                   AND pi.id_professional != i_id_ext_prof_to
                   AND p.id_professional NOT IN (SELECT pto.id_professional_from
                                                   FROM professional_take_over pto
                                                  WHERE pto.flg_status IN ('S', 'F'))
                   AND p.id_professional IN (SELECT pfd.id_professional
                                               FROM professional_field_data pfd, field_market fm
                                              WHERE pfd.value = l_id_category
                                                AND pfd.id_field_market = fm.id_field_market
                                                AND fm.id_field = 43
                                                AND fm.id_market = l_id_market
                                                AND pfd.id_institution = 0);
            ELSE
                SELECT COUNT(p.id_professional)
                  INTO o_ext_prof_count
                  FROM prof_institution pi, professional p
                 WHERE pi.flg_external = pk_alert_constant.get_yes
                   AND pi.flg_state = g_ext_prof_active
                   AND pi.dt_end_tstz IS NULL
                   AND pi.id_institution = i_id_institution
                   AND pi.id_professional = p.id_professional
                   AND pi.id_professional != i_id_ext_prof_to
                   AND p.id_professional NOT IN (SELECT pto.id_professional_from
                                                   FROM professional_take_over pto
                                                  WHERE pto.flg_status IN ('S', 'F'))
                   AND p.id_professional IN (SELECT pfd.id_professional
                                               FROM professional_field_data pfd, field_market fm
                                              WHERE pfd.value = l_id_category
                                                AND pfd.id_field_market = fm.id_field_market
                                                AND fm.id_field = 43
                                                AND fm.id_market = l_id_market
                                                AND pfd.id_institution = 0)
                   AND translate(upper(p.name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%';
            END IF;
        
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
                                              i_function => 'GET_EXT_PROF_LIST_COUNT',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_ext_prof_list_count;

    /********************************************************************************************
    * Returns External Professionals data linked to an Insitution
    *
    * @param i_lang                  Language id
    * @param i_id_institution        Institution identifier
    * @param i_id_ext_prof_to        Professional Take over ID
    * @param i_search                Search
    * @param i_start_record          Paging - initial recrod number
    * @param i_num_records           Paging - number of records to display
    * @param o_error                 Error message
    *
    * @return                        table of external professionals (t_table_ext_prof)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_prof_list_data
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_ext_prof_to IN professional.id_professional%TYPE,
        i_search         IN VARCHAR2,
        i_start_record   IN NUMBER DEFAULT 1,
        i_num_records    IN NUMBER DEFAULT get_num_records
    ) RETURN t_table_ext_prof IS
    
        l_date     t_table_ext_prof;
        l_date_res t_table_ext_prof;
    
        l_id_category professional_field_data.value%TYPE;
        l_id_market   market.id_market%TYPE;
    BEGIN
    
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        IF i_id_ext_prof_to IS NULL
        THEN
        
            IF i_search IS NULL
            THEN
            
                g_error := 'GET EXT_PROF TABLE';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_LIST_DATA ' || g_error);
                SELECT t_rec_ext_prof(p.id_professional,
                                      p.name,
                                      p.zip_code,
                                      p.city,
                                      pto.flg_status,
                                      pto.take_over_time,
                                      pto.id_professional_from,
                                      pto.id_professional_to,
                                      pto.notes,
                                      pi.dn_flg_status)
                  BULK COLLECT
                  INTO l_date
                  FROM prof_institution pi, professional p, professional_take_over pto
                 WHERE pi.flg_external = pk_alert_constant.get_yes
                   AND pi.flg_state = g_ext_prof_active
                   AND pi.dt_end_tstz IS NULL
                   AND pi.id_institution = i_id_institution
                   AND pi.id_professional = p.id_professional
                   AND pto.id_professional_from(+) = p.id_professional
                 ORDER BY p.name;
            
            ELSE
            
                SELECT t_rec_ext_prof(p.id_professional,
                                      p.name,
                                      p.zip_code,
                                      p.city,
                                      pto.flg_status,
                                      pto.take_over_time,
                                      pto.id_professional_from,
                                      pto.id_professional_to,
                                      pto.notes,
                                      pi.dn_flg_status)
                  BULK COLLECT
                  INTO l_date
                  FROM prof_institution pi, professional p, professional_take_over pto
                 WHERE pi.flg_external = pk_alert_constant.get_yes
                   AND pi.flg_state = g_ext_prof_active
                   AND pi.dt_end_tstz IS NULL
                   AND pi.id_institution = i_id_institution
                   AND pi.id_professional = p.id_professional
                   AND pto.id_professional_from(+) = p.id_professional
                   AND translate(upper(p.name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                 ORDER BY p.name;
            
            END IF;
        
        ELSE
        
            SELECT nvl((SELECT pfd.value
                         FROM professional_field_data pfd, field_market fm
                        WHERE pfd.id_professional = i_id_ext_prof_to
                          AND pfd.id_field_market = fm.id_field_market
                          AND fm.id_field = 43
                          AND fm.id_market = l_id_market
                          AND pfd.id_institution = 0),
                       NULL)
              INTO l_id_category
              FROM dual;
        
            IF i_search IS NULL
            THEN
                SELECT t_rec_ext_prof(p.id_professional,
                                      p.name,
                                      p.zip_code,
                                      p.city,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      pi.dn_flg_status)
                  BULK COLLECT
                  INTO l_date
                  FROM prof_institution pi, professional p
                 WHERE pi.flg_external = pk_alert_constant.get_yes
                   AND pi.flg_state = g_ext_prof_active
                   AND pi.dt_end_tstz IS NULL
                   AND pi.id_institution = i_id_institution
                   AND pi.id_professional = p.id_professional
                   AND pi.id_professional != i_id_ext_prof_to
                   AND p.id_professional NOT IN (SELECT pto.id_professional_from
                                                   FROM professional_take_over pto
                                                  WHERE pto.flg_status IN ('S', 'F'))
                   AND p.id_professional IN (SELECT pfd.id_professional
                                               FROM professional_field_data pfd, field_market fm
                                              WHERE pfd.value = l_id_category
                                                AND pfd.id_field_market = fm.id_field_market
                                                AND fm.id_field = 43
                                                AND fm.id_market = l_id_market
                                                AND pfd.id_institution = 0)
                 ORDER BY p.name;
            
            ELSE
                SELECT t_rec_ext_prof(p.id_professional,
                                      p.name,
                                      p.zip_code,
                                      p.city,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      pi.dn_flg_status)
                  BULK COLLECT
                  INTO l_date
                  FROM prof_institution pi, professional p
                 WHERE pi.flg_external = pk_alert_constant.get_yes
                   AND pi.flg_state = g_ext_prof_active
                   AND pi.dt_end_tstz IS NULL
                   AND pi.id_institution = i_id_institution
                   AND pi.id_professional = p.id_professional
                   AND pi.id_professional != i_id_ext_prof_to
                   AND p.id_professional NOT IN (SELECT pto.id_professional_from
                                                   FROM professional_take_over pto
                                                  WHERE pto.flg_status IN ('S', 'F'))
                   AND p.id_professional IN (SELECT pfd.id_professional
                                               FROM professional_field_data pfd, field_market fm
                                              WHERE pfd.value = l_id_category
                                                AND pfd.id_field_market = fm.id_field_market
                                                AND fm.id_field = 43
                                                AND fm.id_market = l_id_market
                                                AND pfd.id_institution = 0)
                   AND translate(upper(p.name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                 ORDER BY p.name;
            
            END IF;
        
        END IF;
    
        g_error := 'GET EXT_PROF TABLE FROM RECORD: ' || to_char(i_start_record) || ' TO RECORD: ' ||
                   to_char(i_start_record + i_num_records - 1);
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_LIST_DATA ' || g_error);
        SELECT t_rec_ext_prof(id_professional,
                              name,
                              zip_code,
                              city,
                              flg_status,
                              take_over_time,
                              id_professional_from,
                              id_professional_to,
                              notes,
                              dn_flg_status)
          BULK COLLECT
          INTO l_date_res
          FROM (SELECT rownum rn, t.*
                  FROM TABLE(CAST(l_date AS t_table_ext_prof)) t)
         WHERE rn BETWEEN i_start_record AND i_start_record + i_num_records - 1;
    
        RETURN l_date_res;
    END;

    /********************************************************************************************
    * Returns External Professionals linked to an Insitution
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional (id, institution, software)
    * @param i_id_institution        Institution identifier
    * @param i_id_ext_prof_to        Professional Take over ID
    * @param i_search                Search
    * @param i_start_record          Paging - initial recrod number
    * @param i_num_records           Paging - number of records to display
    * @param o_ext_prof              External professionals
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_prof_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_ext_prof_to IN professional.id_professional%TYPE,
        i_search         IN VARCHAR2,
        i_start_record   IN NUMBER DEFAULT 1,
        i_num_records    IN NUMBER DEFAULT get_num_records,
        o_ext_prof       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market market.id_market%TYPE;
    
        l_error_out t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
    
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        IF NOT validate_ext_prof_to(i_lang, i_id_institution, l_error_out)
        THEN
            RAISE l_exception;
        ELSE
        
            g_error := 'GET EXT_PROF CURSOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_LIST ' || g_error);
            OPEN o_ext_prof FOR
                SELECT id_professional,
                       pk_backoffice.get_prof_photo_url(i_lang, id_professional) photo,
                       name,
                       get_ext_prof_category(i_lang, id_professional, NULL, l_id_market) category,
                       get_ext_prof_license_number(i_lang, id_professional, NULL, l_id_market) license_number,
                       zip_code,
                       city,
                       nvl(flg_status, pk_alert_constant.get_no) flg_take_over,
                       decode(flg_status,
                              g_ext_prof_to_sch,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T706'),
                              g_ext_prof_to_finished,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T707'),
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T779')) takeover,
                       pk_date_utils.date_send_tsz(i_lang, take_over_time, i_prof) takeover_time,
                       id_professional_from takeover_id_professional_from,
                       id_professional_to takeover_id_professional_to,
                       decode(id_professional_to,
                              NULL,
                              NULL,
                              (SELECT p2.name
                                 FROM professional p2
                                WHERE p2.id_professional = id_professional_to)) takeover_professional_name_to,
                       notes,
                       verifiy_ext_prof_to_possible(i_lang, id_professional) flg_take_over_possible,
                       dn_flg_status dn_flg_status,
                       pk_sysdomain.get_img(i_lang, 'PROF_INSTITUTION.DN_FLG_STATUS', dn_flg_status) dn_flg_status_img,
                       get_ext_prof_list_by_lic_num(i_lang,
                                                    NULL,
                                                    (get_ext_prof_license_number(i_lang,
                                                                                 id_professional,
                                                                                 NULL,
                                                                                 l_id_market)),
                                                    l_id_market,
                                                    i_id_institution) id_stg_professional
                  FROM (SELECT *
                          FROM TABLE(get_ext_prof_list_data(i_lang,
                                                            i_id_institution,
                                                            i_id_ext_prof_to,
                                                            i_search,
                                                            i_start_record,
                                                            i_num_records)))
                 ORDER BY name;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error || ' / ' || l_error_out.err_desc,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_EXT_PROF_LIST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_ext_prof);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_EXT_PROF_LIST',
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(o_ext_prof);
            RETURN FALSE;
    END get_ext_prof_list;

    /********************************************************************************************
    * Returns External Professionals License number
    *
    * @param i_lang                  Language id
    * @param i_id_professional       Professional identifier
    * @param i_id_stg_professional   Staging area External Professional identifier
    * @param i_id_market             Market identifier
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_prof_license_number
    (
        i_lang                IN language.id_language%TYPE,
        i_id_professional     IN professional.id_professional%TYPE,
        i_id_stg_professional IN stg_professional.id_stg_professional%TYPE,
        i_id_market           IN market.id_market%TYPE
    ) RETURN VARCHAR2 IS
    
        l_value VARCHAR2(200 CHAR);
    
        l_error t_error_out;
    
    BEGIN
    
        CASE i_id_market
        -- 17/08/2011 RMGM: add PT and UK condition
            WHEN g_market_pt THEN
                SELECT nvl((SELECT p.num_order
                             FROM professional p
                            WHERE p.id_professional = i_id_professional),
                           NULL)
                  INTO l_value
                  FROM dual;
            
            WHEN g_market_uk THEN
                SELECT nvl((SELECT p.num_order
                             FROM professional p
                            WHERE p.id_professional = i_id_professional),
                           NULL)
                  INTO l_value
                  FROM dual;
            WHEN g_market_nl THEN
                IF i_id_professional IS NOT NULL
                   AND i_id_stg_professional IS NULL
                THEN
                    SELECT nvl((SELECT pfd.value
                                 FROM professional_field_data pfd, field_market fm
                                WHERE pfd.id_professional = i_id_professional
                                  AND pfd.id_field_market = fm.id_field_market
                                  AND fm.id_field = 20
                                  AND fm.id_market = g_market_nl
                                  AND pfd.id_institution = 0
                                  AND rownum = 1),
                               NULL)
                      INTO l_value
                      FROM dual;
                
                ELSIF i_id_stg_professional IS NOT NULL
                      AND i_id_professional IS NULL
                THEN
                    SELECT nvl((SELECT spfd.value
                                 FROM stg_professional_field_data spfd
                                WHERE spfd.id_stg_professional = i_id_stg_professional
                                  AND spfd.id_field = 20
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
                                              i_function => 'GET_EXT_PROF_LICENSE_NUMBER',
                                              o_error    => l_error);
            RETURN NULL;
    END get_ext_prof_license_number;

    /********************************************************************************************
    * Returns External Professionals Category
    *
    * @param i_lang                  Language id
    * @param i_id_professional       Professional identifier
    * @param i_id_stg_professional   Staging area Professional identifier
    * @param i_id_market             Market identifier
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_prof_category
    (
        i_lang                IN language.id_language%TYPE,
        i_id_professional     IN professional.id_professional%TYPE,
        i_id_stg_professional IN stg_professional.id_stg_professional%TYPE,
        i_id_market           IN market.id_market%TYPE
    ) RETURN VARCHAR2 IS
    
        l_value  VARCHAR2(200 CHAR);
        l_value2 VARCHAR2(200 CHAR);
    
        l_error t_error_out;
    
    BEGIN
    
        CASE i_id_market
            WHEN g_market_nl THEN
                IF i_id_professional IS NOT NULL
                   AND i_id_stg_professional IS NULL
                THEN
                    SELECT nvl((SELECT pfd.value
                                 FROM professional_field_data pfd, field_market fm
                                WHERE pfd.id_professional = i_id_professional
                                  AND pfd.id_field_market = fm.id_field_market
                                  AND fm.id_field = 43
                                  AND fm.id_market = g_market_nl
                                  AND pfd.id_institution = 0
                                  AND rownum = 1),
                               NULL)
                      INTO l_value2
                      FROM dual;
                
                    IF l_value2 IS NOT NULL
                    THEN
                    
                        SELECT stgpc.ext_prof_cat_desc
                          INTO l_value
                          FROM stg_ext_prof_cat stgpc
                         WHERE stgpc.id_ext_prof_cat = to_number(l_value2)
                           AND stgpc.id_market = g_market_nl;
                    
                    END IF;
                
                ELSIF i_id_stg_professional IS NOT NULL
                      AND i_id_professional IS NULL
                THEN
                    SELECT nvl((SELECT stgpfd.value
                                 FROM stg_professional_field_data stgpfd
                                WHERE stgpfd.id_stg_professional = i_id_stg_professional
                                  AND stgpfd.id_field = 43),
                               NULL)
                      INTO l_value2
                      FROM dual;
                
                    IF l_value2 IS NOT NULL
                    THEN
                    
                        SELECT stgpc.ext_prof_cat_desc
                          INTO l_value
                          FROM stg_ext_prof_cat stgpc
                         WHERE stgpc.id_ext_prof_cat = to_number(l_value2)
                           AND stgpc.id_market = g_market_nl;
                    
                    END IF;
                
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
                                              i_function => 'GET_EXT_PROF_CATEGORY',
                                              o_error    => l_error);
            RETURN NULL;
    END get_ext_prof_category;

    /********************************************************************************************
    * Returns External Professionals Personal data
    *
    * @param i_lang                  Language id
    * @param i_id_professional       Professional identifier
    * @param i_id_market             Market identifier
    * @param o_ext_prof_data         Personal data in professional table
    * @param o_ext_prof_field_data   Personal data from a specific country
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_prof_personal_data
    (
        i_lang                IN language.id_language%TYPE,
        i_id_professional     IN professional.id_professional%TYPE,
        i_id_market           IN market.id_market%TYPE,
        o_ext_prof_data       OUT pk_types.cursor_type,
        o_ext_prof_field_data OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_res CLOB;
    
    BEGIN
    
        pk_context_api.set_parameter('i_lang', i_lang);
        pk_context_api.set_parameter('i_id_professional', i_id_professional);
        pk_context_api.set_parameter('i_res', l_res);
    
        IF i_id_professional IS NULL
        THEN
        
            g_error := 'GET EXT_PROF_DATA CURSOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_PERSONAL_DATA ' || g_error);
            OPEN o_ext_prof_data FOR
                SELECT NULL id_field_market,
                       NULL id_field,
                       decode(r,
                              1,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T364'),
                              2,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T278'),
                              3,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T290'),
                              4,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T288'),
                              5,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T292'),
                              6,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T253'),
                              7,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T293')) field_name,
                       decode(r, 1, 'M', 2, 'T', 3, 'T', 4, 'T', 5, 'T', 6, 'M', 7, 'D') field_fill_type,
                       decode(r,
                              1,
                              get_ext_prof_mc_values(i_lang, i_id_professional, 1, 1, 1),
                              6,
                              get_ext_prof_mc_values(i_lang, i_id_professional, 1, 6, 1)) multichoice_id,
                       decode(r,
                              1,
                              get_ext_prof_mc_values(i_lang, i_id_professional, 1, 1, 2),
                              6,
                              get_ext_prof_mc_values(i_lang, i_id_professional, 1, 6, 2)) multichoice_desc,
                       NULL field_value,
                       NULL field_value_desc,
                       NULL id_institution,
                       decode(r, 1, 10, 2, 20, 3, 30, 4, 40, 5, 50, 6, 70, 7, 60) rank,
                       decode(r,
                              1,
                              'i_title',
                              2,
                              'i_first_name',
                              3,
                              'i_middle_name',
                              4,
                              'i_last_name',
                              5,
                              'i_initials',
                              6,
                              'i_gender',
                              7,
                              'i_dt_birth') set_parameters
                  FROM (SELECT rownum r
                          FROM all_objects
                         WHERE rownum <= 7)
                 ORDER BY rank;
        
            g_error := 'GET EXT_PROF_DATA CURSOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_PERSIONAL_DATA ' || g_error);
            OPEN o_ext_prof_field_data FOR
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
                 WHERE f.flg_field_prof_inst = 'P'
                   AND f.flg_available = pk_alert_constant.get_available
                   AND f.id_field_type = 1
                   AND f.id_field = fm.id_field
                   AND fm.id_market = i_id_market
                   AND fm.flg_available = pk_alert_constant.get_available;
        
        ELSE
        
            g_error := 'GET EXT_PROF_DATA CURSOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_PERSONAL_DATA ' || g_error);
            OPEN o_ext_prof_data FOR
                SELECT NULL id_field_market,
                       NULL id_field,
                       decode(r,
                              1,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T364'),
                              2,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T278'),
                              3,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T290'),
                              4,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T288'),
                              5,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T292'),
                              6,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T253'),
                              7,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T293')) field_name,
                       decode(r, 1, 'M', 2, 'T', 3, 'T', 4, 'T', 5, 'T', 6, 'M', 7, 'D') field_fill_type,
                       decode(r,
                              1,
                              get_ext_prof_mc_values(i_lang, i_id_professional, 1, 1, 1),
                              6,
                              get_ext_prof_mc_values(i_lang, i_id_professional, 1, 6, 1)) multichoice_id,
                       decode(r,
                              1,
                              get_ext_prof_mc_values(i_lang, i_id_professional, 1, 1, 2),
                              6,
                              get_ext_prof_mc_values(i_lang, i_id_professional, 1, 6, 2)) multichoice_desc,
                       decode(r,
                              1,
                              get_ext_prof_mc_values(i_lang, i_id_professional, 1, 1, 3),
                              2,
                              p.first_name,
                              3,
                              p.middle_name,
                              4,
                              p.last_name,
                              5,
                              p.initials,
                              6,
                              get_ext_prof_mc_values(i_lang, i_id_professional, 1, 6, 3),
                              7,
                              pk_backoffice.get_date_to_be_sent(i_lang, p.dt_birth)) field_value,
                       decode(r,
                              1,
                              get_ext_prof_mc_values(i_lang, i_id_professional, 1, 1, 4),
                              2,
                              p.first_name,
                              3,
                              p.middle_name,
                              4,
                              p.last_name,
                              5,
                              p.initials,
                              6,
                              get_ext_prof_mc_values(i_lang, i_id_professional, 1, 6, 4),
                              7,
                              pk_backoffice.get_date_to_be_sent(i_lang, p.dt_birth)) field_value_desc,
                       NULL id_institution,
                       decode(r, 1, 10, 2, 20, 3, 30, 4, 40, 5, 50, 6, 70, 7, 60) rank,
                       decode(r,
                              1,
                              'i_title',
                              2,
                              'i_first_name',
                              3,
                              'i_middle_name',
                              4,
                              'i_last_name',
                              5,
                              'i_initials',
                              6,
                              'i_gender',
                              7,
                              'i_dt_birth') set_parameters
                  FROM professional p,
                       (SELECT rownum r
                          FROM all_objects
                         WHERE rownum <= 7)
                 WHERE p.id_professional = i_id_professional
                 ORDER BY rank;
        
            g_error := 'GET EXT_PROF_DATA CURSOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_PERSIONAL_DATA ' || g_error);
            OPEN o_ext_prof_field_data FOR
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
                       pfd.value field_value,
                       decode(fm.fill_type, 'M', NULL, pfd.value) field_value_desc,
                       0 id_institution,
                       f.rank rank,
                       NULL set_parameters
                  FROM field f, field_market fm, professional_field_data pfd
                 WHERE f.flg_field_prof_inst = 'P'
                   AND f.flg_available = pk_alert_constant.get_available
                   AND f.id_field_type = 1
                   AND f.id_field = fm.id_field
                   AND fm.id_market = i_id_market
                   AND fm.flg_available = pk_alert_constant.get_available
                   AND pfd.id_professional(+) = i_id_professional
                   AND pfd.id_field_market = fm.id_field_market;
        
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
                                              i_function => 'GET_EXT_PROF_PERSONAL_DTA',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_ext_prof_data);
            pk_types.open_my_cursor(o_ext_prof_field_data);
            RETURN FALSE;
        
    END get_ext_prof_personal_data;

    /********************************************************************************************
    /********************************************************************************************
     * Returns External Professionals Personal contacts
     *
     * @param i_lang                      Language id
     * @param i_id_professional           Professional identifier
     * @param i_id_market                 Market identifier
     * @param o_ext_prof_contacts         Personal contacts in professional table
     * @param o_ext_prof_field_contacts   Personal contacts from a specific country
     * @param o_error                     Error message
     *
     * @return                        true (sucess), false (error)
     *
     * @author                        Tércio Soares
     * @since                         2010/06/02
     * @version                       2.6.0.3
     ********************************************************************************************/
    FUNCTION get_ext_prof_personal_contacts
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_professional         IN professional.id_professional%TYPE,
        i_id_market               IN market.id_market%TYPE,
        o_ext_prof_contacts       OUT pk_types.cursor_type,
        o_ext_prof_field_contacts OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_id_professional IS NULL
        THEN
            g_error := 'GET EXT_PROF_CONTACTS CURSOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_PERSONAL_CONTACTS' || g_error);
            OPEN o_ext_prof_contacts FOR
                SELECT NULL id_field_market,
                       NULL id_field,
                       decode(r,
                              1,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T286'),
                              2,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T287'),
                              3,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T262'),
                              4,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T254'),
                              5,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T255'),
                              6,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T269'),
                              7,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T268'),
                              8,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T265')) field_name,
                       decode(r, 1, 'T', 2, 'T', 3, 'T', 4, 'T', 5, 'T', 6, 'T', 7, 'T', 8, 'M') field_fill_type,
                       decode(r, 8, get_ext_prof_mc_values(i_lang, i_id_professional, 2, 8, 1)) multichoice_id,
                       to_clob(decode(r, 8, get_ext_prof_mc_values(i_lang, i_id_professional, 2, 8, 2))) multichoice_desc,
                       NULL field_value,
                       NULL field_value_desc,
                       NULL id_institution,
                       decode(r, 1, 10, 2, 40, 3, 50, 4, 100, 5, 110, 6, 120, 7, 130, 8, 60) rank,
                       decode(r,
                              1,
                              'i_street',
                              2,
                              'i_zip_code',
                              3,
                              'i_city',
                              4,
                              'i_phone',
                              5,
                              'i_cell_phone',
                              6,
                              'i_fax',
                              7,
                              'i_email',
                              8,
                              'i_id_country') set_parameters
                  FROM (SELECT rownum r
                          FROM all_objects
                         WHERE rownum <= 8)
                 ORDER BY rank;
        
            g_error := 'GET EXT_PROF_DATA CURSOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_PERSIONAL_DATA ' || g_error);
            OPEN o_ext_prof_field_contacts FOR
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
                 WHERE f.flg_field_prof_inst = 'P'
                   AND f.flg_available = pk_alert_constant.get_available
                   AND f.id_field_type = 2
                   AND f.id_field = fm.id_field
                   AND fm.id_market = i_id_market
                   AND fm.flg_available = pk_alert_constant.get_available
                 ORDER BY rank;
        ELSE
        
            g_error := 'GET EXT_PROF_CONTACTS CURSOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_PERSONAL_CONTACTS' || g_error);
            OPEN o_ext_prof_contacts FOR
                SELECT NULL id_field_market,
                       NULL id_field,
                       decode(r,
                              1,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T286'),
                              2,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T287'),
                              3,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T262'),
                              4,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T254'),
                              5,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T255'),
                              6,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T269'),
                              7,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T268'),
                              8,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T265')) field_name,
                       decode(r, 1, 'T', 2, 'T', 3, 'T', 4, 'T', 5, 'T', 6, 'T', 7, 'T', 8, 'M') field_fill_type,
                       decode(r, 8, get_ext_prof_mc_values(i_lang, i_id_professional, 2, 8, 1)) multichoice_id,
                       to_clob(decode(r, 8, get_ext_prof_mc_values(i_lang, i_id_professional, 2, 8, 2))) multichoice_desc,
                       decode(r,
                              1,
                              p.address,
                              2,
                              p.zip_code,
                              3,
                              p.city,
                              4,
                              p.num_contact,
                              5,
                              p.cell_phone,
                              6,
                              p.fax,
                              7,
                              p.email,
                              8,
                              get_ext_prof_mc_values(i_lang, i_id_professional, 2, 8, 3)) field_value,
                       decode(r,
                              1,
                              p.address,
                              2,
                              p.zip_code,
                              3,
                              p.city,
                              4,
                              p.num_contact,
                              5,
                              p.cell_phone,
                              6,
                              p.fax,
                              7,
                              p.email,
                              8,
                              get_ext_prof_mc_values(i_lang, i_id_professional, 2, 8, 4)) field_value_desc,
                       NULL id_institution,
                       decode(r, 1, 10, 2, 40, 3, 50, 4, 100, 5, 110, 6, 120, 7, 130, 8, 60) rank,
                       decode(r,
                              1,
                              'i_street',
                              2,
                              'i_zip_code',
                              3,
                              'i_city',
                              4,
                              'i_phone',
                              5,
                              'i_cell_phone',
                              6,
                              'i_fax',
                              7,
                              'i_email',
                              8,
                              'i_id_country') set_parameters
                  FROM professional p,
                       (SELECT rownum r
                          FROM all_objects
                         WHERE rownum <= 8)
                 WHERE p.id_professional = i_id_professional
                 ORDER BY rank;
        
            g_error := 'GET EXT_PROF_DATA CURSOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_PERSIONAL_DATA ' || g_error);
            OPEN o_ext_prof_field_contacts FOR
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
                       pfd.value field_value,
                       decode(fm.fill_type, 'M', NULL, pfd.value) field_value_desc,
                       0 id_institution,
                       f.rank rank,
                       NULL set_parameters
                  FROM field f, field_market fm, professional_field_data pfd
                 WHERE f.flg_field_prof_inst = 'P'
                   AND f.flg_available = pk_alert_constant.get_available
                   AND f.id_field_type = 2
                   AND f.id_field = fm.id_field
                   AND fm.id_market = i_id_market
                   AND fm.flg_available = pk_alert_constant.get_available
                   AND pfd.id_professional(+) = i_id_professional
                   AND pfd.id_field_market(+) = fm.id_field_market
                 ORDER BY rank;
        
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
                                              i_function => 'GET_EXT_PROF_PERSONAL_CONTATCS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_ext_prof_contacts);
            pk_types.open_my_cursor(o_ext_prof_field_contacts);
            RETURN FALSE;
        
    END get_ext_prof_personal_contacts;

    /********************************************************************************************
    * Returns External Professionals professional data
    *
    * @param i_lang                        Language id
    * @param i_id_professional             Professional identifier
    * @param i_id_market                   MArket identifier
    * @param o_ext_prof_professional       Professional data in professional table
    * @param o_ext_prof_field_professinal  Professional data from a specific country
    * @param o_error                       Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_prof_professional_data
    (
        i_lang                       IN language.id_language%TYPE,
        i_id_professional            IN professional.id_professional%TYPE,
        i_id_market                  IN market.id_market%TYPE,
        o_ext_prof_professional      OUT pk_types.cursor_type,
        o_ext_prof_field_professinal OUT pk_types.cursor_type,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_id_professional IS NULL
        THEN
            g_error := 'GET EXT_PROF_PROFESSIONAL CURSOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_PERSONAL_DATA ' || g_error);
            OPEN o_ext_prof_professional FOR
                SELECT NULL id_field_market,
                       NULL id_field,
                       decode(r,
                              1,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_IDENT_T003'),
                              2,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_IDENT_T009')) field_name,
                       decode(r, 1, 'T', 2, 'M') field_fill_type,
                       decode(r, 2, get_ext_prof_mc_values(i_lang, i_id_professional, 3, 2, 1)) multichoice_id,
                       to_clob(decode(r, 2, get_ext_prof_mc_values(i_lang, i_id_professional, 3, 2, 2))) multichoice_desc,
                       NULL field_value,
                       NULL field_value_desc,
                       NULL id_institution,
                       decode(r, 1, 1, 2, 2) rank,
                       decode(r, 1, 'i_num_order', 2, 'i_speciality') set_parameters
                  FROM (SELECT rownum r
                          FROM all_objects
                         WHERE rownum <= 2)
                 ORDER BY rank;
        
            g_error := 'GET EXT_PROF_FIELD_PROFESSIONAL CURSOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_PERSIONAL_DATA ' || g_error);
            OPEN o_ext_prof_field_professinal FOR
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
                 WHERE f.flg_field_prof_inst = 'P'
                   AND f.flg_available = pk_alert_constant.get_available
                   AND f.id_field_type = 3
                   AND f.id_field = fm.id_field
                   AND fm.id_market = i_id_market
                   AND fm.flg_available = pk_alert_constant.get_available
                 ORDER BY rank;
        ELSE
        
            g_error := 'GET EXT_PROF_PROFESSIONAL CURSOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_PERSONAL_DATA ' || g_error);
            OPEN o_ext_prof_professional FOR
                SELECT NULL id_field_market,
                       NULL id_field,
                       decode(r,
                              1,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_IDENT_T003'),
                              2,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_IDENT_T009')) field_name,
                       decode(r, 1, 'T', 2, 'M') field_fill_type,
                       decode(r, 2, (get_ext_prof_mc_values(i_lang, i_id_professional, 3, 2, 1))) multichoice_id,
                       to_clob(decode(r, 2, (get_ext_prof_mc_values(i_lang, i_id_professional, 3, 2, 2)))) multichoice_desc,
                       decode(r, 1, p.num_order, 2, get_ext_prof_mc_values(i_lang, i_id_professional, 3, 2, 3)) field_value,
                       decode(r, 1, p.num_order, 2, get_ext_prof_mc_values(i_lang, i_id_professional, 3, 2, 4)) field_value_desc,
                       NULL id_institution,
                       decode(r, 1, 1, 2, 2) rank,
                       decode(r, 1, 'i_num_order', 2, 'i_speciality') set_parameters
                  FROM professional p,
                       (SELECT rownum r
                          FROM all_objects
                         WHERE rownum <= 2)
                 WHERE p.id_professional = i_id_professional
                 ORDER BY rank;
        
            g_error := 'GET EXT_PROF_FIELD_PROFESSIONAL CURSOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_PROFESSIONAL_DATA ' || g_error);
            OPEN o_ext_prof_field_professinal FOR
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
                       pfd.value field_value,
                       decode(fm.fill_type, 'M', NULL, pfd.value) field_value_desc,
                       0 id_institution,
                       f.rank rank,
                       NULL set_parameters
                  FROM field f, field_market fm, professional_field_data pfd
                 WHERE f.flg_field_prof_inst = 'P'
                   AND f.flg_available = pk_alert_constant.get_available
                   AND f.id_field_type = 3
                   AND f.id_field = fm.id_field
                   AND fm.id_market = i_id_market
                   AND fm.flg_available = pk_alert_constant.get_available
                   AND pfd.id_professional(+) = i_id_professional
                   AND pfd.id_field_market(+) = fm.id_field_market
                 ORDER BY rank;
        
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
                                              i_function => 'GET_EXT_PROF_PROFESSIONAL_DATA',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_ext_prof_professional);
            pk_types.open_my_cursor(o_ext_prof_field_professinal);
            RETURN FALSE;
        
    END get_ext_prof_professional_data;

    /********************************************************************************************
    * Returns External Professionals professional data
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional (id, institution, software)
    * @param i_id_professional       Professional identifier
    * @param o_ext_prof_institutions Professional institutions
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_prof_institutions_data
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_professional       IN professional.id_professional%TYPE,
        o_ext_prof_institutions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET EXT_PROF_FIELD_PROFESSIONAL CURSOR';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_PROFESSIONAL_DATA ' || g_error);
        OPEN o_ext_prof_institutions FOR
            SELECT i.id_institution,
                   pk_translation.get_translation(i_lang, i.code_institution) institution_name,
                   (SELECT date_1
                      FROM (SELECT pk_date_utils.date_send_tsz(i_lang, pi2.dt_begin_tstz, i_prof) date_1,
                                   pi2.id_institution
                              FROM prof_institution pi2
                             WHERE pi2.id_professional = i_id_professional
                             ORDER BY pi2.dt_begin_tstz ASC)
                     WHERE id_institution = pi.id_institution
                       AND rownum = 1) dt_begin_tstz,
                   NULL dt_end_tstz,
                   pi.flg_state,
                   pk_sysdomain.get_domain('PROF_INSTITUTION.FLG_STATE', pi.flg_state, i_lang) flg_state_desc,
                   pk_alert_constant.get_no flg_edit
              FROM prof_institution pi, institution i
             WHERE pi.id_professional = i_id_professional
               AND pi.id_institution = i.id_institution
               AND pi.dt_end_tstz IS NULL
               AND pi.flg_external = pk_alert_constant.get_no
               AND i.flg_external = pk_alert_constant.get_no
            UNION
            SELECT i.id_institution,
                   pk_translation.get_translation(i_lang, i.code_institution) institution_name,
                   pk_date_utils.date_send_tsz(i_lang, pi.dt_begin_tstz, i_prof) dt_begin_tstz,
                   pk_date_utils.date_send_tsz(i_lang, pi.dt_end_tstz, i_prof) dt_end_tstz,
                   pi.flg_state,
                   pk_sysdomain.get_domain('PROF_INSTITUTION.FLG_STATE', pi.flg_state, i_lang) flg_state_desc,
                   pk_alert_constant.get_yes flg_edit
              FROM prof_institution pi, institution i
             WHERE pi.id_professional = i_id_professional
               AND pi.id_institution = i.id_institution
               AND pi.flg_external = pk_alert_constant.get_no
               AND i.flg_external = pk_alert_constant.get_yes
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
                                              i_function => 'GET_EXT_PROF_INSTITUTIONS_DATA',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_ext_prof_institutions);
            RETURN FALSE;
        
    END get_ext_prof_institutions_data;

    /********************************************************************************************
    * Update/insert information for an external professional
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_professional       Professional ID
    * @param i_title                 Professional Title
    * @param i_first_name            Professional first name
    * @param i_middle_name           Professional middle name
    * @param i_last_name             Professional last name
    * @param i_initials              Professional initials
    * @param i_dt_birth              Professional Date of Birth
    * @param i_gender                Professioanl gender
    * @param i_street                Professional adress
    * @param i_zip_code              Professional zip code
    * @param i_city                  Professional city
    * @param i_phone                 Professional phone
    * @param i_cell_phone            Professional mobile phone
    * @param i_fax                   Professional fax
    * @param i_email                 Professional email
    * @param i_num_order             Professional license number
    * @param i_id_institution        Institution ID
    * @param i_fields                List of dynamic fields
    * @param i_institution           Institutins for the dynamic fields
    * @param i_values                Information values for the dynamic fields
    * @param o_professional          Professional ID
    * @param o_error                 error    
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION set_ext_professional
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_title           IN professional.title%TYPE,
        i_first_name      IN professional.first_name%TYPE,
        i_middle_name     IN professional.middle_name%TYPE,
        i_last_name       IN professional.last_name%TYPE,
        i_initials        IN professional.initials%TYPE,
        i_dt_birth        IN VARCHAR2,
        i_gender          IN professional.gender%TYPE,
        i_street          IN professional.address%TYPE,
        i_zip_code        IN professional.zip_code%TYPE,
        i_city            IN professional.city%TYPE,
        i_id_country      IN professional.id_country%TYPE,
        i_phone           IN professional.num_contact%TYPE,
        i_cell_phone      IN professional.cell_phone%TYPE,
        i_fax             IN professional.fax%TYPE,
        i_email           IN professional.email%TYPE,
        i_num_order       IN professional.num_order%TYPE,
        i_speciality      IN professional.id_speciality%TYPE,
        i_id_institution  IN prof_institution.id_institution%TYPE,
        i_fields          IN table_number,
        i_institution     IN table_number,
        i_values          IN table_varchar,
        o_professional    OUT professional.id_professional%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error t_error_out;
    
    BEGIN
    
        IF NOT pk_backoffice.set_ext_professional(i_lang           => i_lang,
                                                  i_id_prof        => i_id_professional,
                                                  i_title          => i_title,
                                                  i_first_name     => i_first_name,
                                                  i_parent_name    => NULL,
                                                  i_middle_name    => i_middle_name,
                                                  i_last_name      => i_last_name,
                                                  i_nickname       => i_first_name,
                                                  i_initials       => i_initials,
                                                  i_dt_birth       => pk_backoffice.get_date_received(i_lang, i_dt_birth),
                                                  i_gender         => i_gender,
                                                  i_marital_status => NULL,
                                                  i_id_speciality  => i_speciality,
                                                  i_num_order      => i_num_order,
                                                  i_address        => i_street,
                                                  i_city           => i_city,
                                                  i_district       => NULL,
                                                  i_zip_code       => i_zip_code,
                                                  i_id_country     => i_id_country,
                                                  i_phone          => i_phone,
                                                  i_num_contact    => i_phone,
                                                  i_mobile_phone   => i_cell_phone,
                                                  i_fax            => i_fax,
                                                  i_email          => i_email,
                                                  i_id_institution => i_id_institution,
                                                  i_commit_at_end  => FALSE,
                                                  o_professional   => o_professional,
                                                  o_error          => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        FOR i IN 1 .. i_fields.count
        LOOP
        
            g_error := 'MERGE INTO PROFESSIONAL_FIELD_DATA';
            MERGE INTO professional_field_data pfd
            USING (SELECT i_fields(i) fld, i_values(i) val, i_institution(i) inst
                     FROM dual) t
            ON (pfd.id_field_market = t.fld AND pfd.id_professional = o_professional AND pfd.id_institution = t.inst)
            WHEN MATCHED THEN
                UPDATE
                   SET pfd.value = t.val
            WHEN NOT MATCHED THEN
                INSERT
                    (id_professional, id_field_market, VALUE, id_institution)
                VALUES
                    (o_professional, t.fld, t.val, t.inst);
        
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
                                              i_function => 'SET_EXT_PROFESSIONAL',
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
                                              i_function => 'SET_EXT_PROFESSIONAL',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_ext_professional;

    /********************************************************************************************
    * Update/insert information for an external user linked to external institutions
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional (id, institution, software)
    * @param i_id_professional       External Professional ID
    * @param i_institution           External institutions ID's
    * @param i_dt_begin              External institutions and professional relation: Date begin
    * @param i_dt_begin              External institutions and professional relation: Date end
    * @param i_flg_state             External institutions and professional relation: State
    * @param i_inst_delete           External associations to delete
    * @param o_error                 error    
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION set_ext_prof_institution
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        i_institution     IN table_number,
        i_dt_begin        IN table_varchar,
        i_dt_end          IN table_varchar,
        i_flg_state       IN table_varchar,
        i_inst_delete     IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_prof_institution prof_institution.id_prof_institution%TYPE := 0;
        CURSOR c_inst(i_institution_id institution.id_institution%TYPE) IS
            SELECT p_inst.id_prof_institution
              FROM (SELECT x.*
                      FROM prof_institution x
                     WHERE x.id_institution = i_institution_id
                       AND x.id_professional = i_id_professional
                     ORDER BY x.dt_end_tstz DESC) p_inst;
        l_inst prof_institution.id_prof_institution%TYPE := NULL;
    
    BEGIN
        FOR i IN 1 .. i_inst_delete.count
        LOOP
        
            g_error := 'DELETE ASSOCIATIONS BETWEEN EXTERNAL PROFESSIONAL AND EXTERNAL INSTITUTIONS';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.SET_EXT_PROF_INSTITUTION ' || g_error);
            pk_api_ab_tables.del_from_prof_institution('id_professional = ' || i_id_professional || '
               AND id_institution = ' || i_inst_delete(i));
        
        END LOOP;
    
        FOR j IN 1 .. i_institution.count
        LOOP
            g_error := 'GET PROF INSTITUION RELATION ID';
            pk_alertlog.log_debug(g_error || ' - ' || i_id_professional || ', ' || i_institution(j));
            OPEN c_inst(i_institution(j));
            FETCH c_inst
                INTO l_inst;
        
            CLOSE c_inst;
            g_error := 'SET ASSOCIATIONS BETWEEN EXTERNAL PROFESSIONAL AND EXTERNAL INSTITUTIONS';
            pk_alertlog.log_debug(g_error || ' EXISTS ' || l_inst || ' OR NEW -> ' || i_id_professional || ', ' ||
                                  i_institution(j));
            pk_api_ab_tables.upd_ins_into_prof_institution(i_id_prof_institution => l_inst,
                                                           i_id_professional     => i_id_professional,
                                                           i_id_institution      => i_institution(j),
                                                           i_flg_state           => i_flg_state(j),
                                                           i_dt_begin_tstz       => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                  i_prof,
                                                                                                                  i_dt_begin(j),
                                                                                                                  NULL),
                                                           i_dt_end_tstz         => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                  i_prof,
                                                                                                                  i_dt_end(j),
                                                                                                                  NULL),
                                                           i_flg_external        => pk_alert_constant.get_no,
                                                           o_id_prof_institution => l_prof_institution);
            l_inst := NULL;
        
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
                                              i_function => 'SET_EXT_PROF_INSTITUTION',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_ext_prof_institution;

    /********************************************************************************************
    * Count external professionals
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institutions ID
    * @param i_name                  External professional name
    * @param i_category              External professional Type
    * @param i_city                  External professional City
    * @param i_postal_code           External professional Postal Code
    * @param i_postal_code_from      External professionals range of postal codes
    * @param i_postal_code_to        External professionals range of postal codes
    * @param i_search                Search
    * @param o_ext_prof_count        List of external professionals
    * @param o_error                 error    
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        Tércio Soares
    * @since                         2010/06/03
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION find_ext_prof_count
    (
        i_lang             IN language.id_language%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_name             IN professional.name%TYPE,
        i_category         IN VARCHAR2,
        i_city             IN professional.city%TYPE,
        i_postal_code      IN professional.zip_code%TYPE,
        i_postal_code_from IN professional.zip_code%TYPE,
        i_postal_code_to   IN professional.zip_code%TYPE,
        i_search           IN VARCHAR2,
        o_ext_prof_count   OUT NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market market.id_market%TYPE;
    
        l_license_array table_varchar := table_varchar();
    
        l_count_1_p     NUMBER := 0;
        l_count_2_p     NUMBER := 0;
        l_count_3_p1    NUMBER := 0;
        l_count_3_p2    NUMBER := 0;
        l_count_1_stgp  NUMBER := 0;
        l_count_2_stgp  NUMBER := 0;
        l_count_3_stgp1 NUMBER := 0;
        l_count_3_stgp2 NUMBER := 0;
    
    BEGIN
    
        g_error := 'GET INSTITUTION MARKET';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.FIND_EXT_PROF ' || g_error);
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        g_error := 'GET EXT_PROF LINKED TO INSTITUTION (ID: ' || i_id_institution || ' ) LICENSES';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.FIND_EXT_PROF ' || g_error);
        SELECT license_number
          BULK COLLECT
          INTO l_license_array
          FROM (SELECT DISTINCT get_ext_prof_license_number(i_lang, p.id_professional, NULL, l_id_market) license_number
                  FROM professional p, prof_institution pi
                 WHERE pi.flg_external = pk_alert_constant.get_yes
                   AND pi.flg_state = g_ext_prof_active
                   AND pi.dt_end_tstz IS NULL
                   AND pi.id_institution = i_id_institution
                   AND pi.id_professional = p.id_professional
                   AND nvl(p.flg_prof_test, pk_alert_constant.get_no) = pk_alert_constant.get_no)
         WHERE license_number IS NOT NULL;
    
        IF i_postal_code IS NULL
           AND i_postal_code_from IS NULL
           AND i_postal_code_to IS NULL
        THEN
        
            IF i_search IS NULL
            THEN
            
                g_error := 'GET EXT_PROF_LIST COUNT';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.FIND_EXT_PROF ' || g_error);
                SELECT COUNT(DISTINCT p.id_professional)
                  INTO l_count_1_p
                  FROM professional p, prof_institution pi
                 WHERE pi.flg_external = pk_alert_constant.get_yes
                   AND pi.flg_state = g_ext_prof_active
                   AND pi.dt_end_tstz IS NULL
                   AND pi.id_institution = i_id_institution
                   AND pi.id_professional = p.id_professional
                   AND nvl(p.flg_prof_test, pk_alert_constant.get_no) = pk_alert_constant.get_no
                   AND (p.name IS NULL OR
                       (translate(lower(p.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market) IS NULL OR
                       (translate(lower(get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(lower(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (p.city IS NULL OR
                       (translate(lower(p.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')));
            
                SELECT COUNT(DISTINCT stgp.id_stg_professional)
                  INTO l_count_1_stgp
                  FROM stg_professional stgp
                 WHERE stgp.id_institution = i_id_institution
                   AND (stgp.name IS NULL OR
                       (translate(lower(stgp.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (get_ext_prof_category(i_lang, NULL, stgp.id_stg_professional, l_id_market) IS NULL OR
                       (translate(lower(get_ext_prof_category(i_lang, NULL, stgp.id_stg_professional, l_id_market)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(lower(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgp.city IS NULL OR
                       (translate(lower(stgp.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND get_ext_prof_license_number(i_lang, NULL, stgp.id_stg_professional, l_id_market) NOT IN
                       (SELECT column_value
                          FROM TABLE(CAST(l_license_array AS table_varchar)));
            
            ELSE
            
                g_error := 'GET EXT_PROF_LIST COUNT';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.FIND_EXT_PROF ' || g_error);
                SELECT COUNT(DISTINCT p.id_professional)
                  INTO l_count_1_p
                  FROM professional p, prof_institution pi
                 WHERE pi.flg_external = pk_alert_constant.get_yes
                   AND pi.flg_state = g_ext_prof_active
                   AND pi.dt_end_tstz IS NULL
                   AND pi.id_institution = i_id_institution
                   AND pi.id_professional = p.id_professional
                   AND nvl(p.flg_prof_test, pk_alert_constant.get_no) = pk_alert_constant.get_no
                   AND (p.name IS NULL OR
                       (translate(lower(p.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND translate(upper(p.name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                   AND (get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market) IS NULL OR
                       (translate(lower(get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(lower(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (p.city IS NULL OR
                       (translate(lower(p.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')));
            
                SELECT COUNT(DISTINCT stgp.id_stg_professional)
                  INTO l_count_1_stgp
                  FROM stg_professional stgp
                 WHERE stgp.id_institution = i_id_institution
                   AND (stgp.name IS NULL OR
                       (translate(lower(stgp.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND translate(upper(stgp.name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                   AND (get_ext_prof_category(i_lang, NULL, stgp.id_stg_professional, l_id_market) IS NULL OR
                       (translate(lower(get_ext_prof_category(i_lang, NULL, stgp.id_stg_professional, l_id_market)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(lower(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgp.city IS NULL OR
                       (translate(lower(stgp.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND get_ext_prof_license_number(i_lang, NULL, stgp.id_stg_professional, l_id_market) NOT IN
                       (SELECT column_value
                          FROM TABLE(CAST(l_license_array AS table_varchar)));
            
            END IF;
        
            o_ext_prof_count := l_count_1_p + l_count_1_stgp;
        
        ELSIF i_postal_code IS NOT NULL
        THEN
        
            IF i_search IS NULL
            THEN
                g_error := 'GET EXT_PROF_LIST CURSOR';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.FIND_EXT_PROF ' || g_error);
                SELECT COUNT(DISTINCT p.id_professional)
                  INTO l_count_2_p
                  FROM professional p, prof_institution pi
                 WHERE pi.flg_external = pk_alert_constant.get_yes
                   AND pi.flg_state = g_ext_prof_active
                   AND pi.dt_end_tstz IS NULL
                   AND pi.id_institution = i_id_institution
                   AND pi.id_professional = p.id_professional
                   AND nvl(p.flg_prof_test, pk_alert_constant.get_no) = pk_alert_constant.get_no
                   AND (p.name IS NULL OR
                       (translate(lower(p.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market) IS NULL OR
                       (translate(lower(get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(lower(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (p.city IS NULL OR
                       (translate(lower(p.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (p.zip_code IS NULL OR
                       (translate(lower(p.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(lower(i_postal_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')));
            
                SELECT COUNT(DISTINCT stgp.id_stg_professional)
                  INTO l_count_2_stgp
                  FROM stg_professional stgp
                 WHERE stgp.id_institution = i_id_institution
                   AND (stgp.name IS NULL OR
                       (translate(lower(stgp.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (get_ext_prof_category(i_lang, NULL, stgp.id_stg_professional, l_id_market) IS NULL OR
                       (translate(lower(get_ext_prof_category(i_lang, NULL, stgp.id_stg_professional, l_id_market)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(lower(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgp.city IS NULL OR
                       (translate(lower(stgp.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgp.zip_code IS NULL OR
                       (translate(lower(stgp.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(lower(i_postal_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND get_ext_prof_license_number(i_lang, NULL, stgp.id_stg_professional, l_id_market) NOT IN
                       (SELECT column_value
                          FROM TABLE(CAST(l_license_array AS table_varchar)));
            
            ELSE
                g_error := 'GET EXT_PROF_LIST CURSOR';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.FIND_EXT_PROF ' || g_error);
                SELECT COUNT(DISTINCT p.id_professional)
                  INTO l_count_2_p
                  FROM professional p, prof_institution pi
                 WHERE pi.flg_external = pk_alert_constant.get_yes
                   AND pi.flg_state = g_ext_prof_active
                   AND pi.dt_end_tstz IS NULL
                   AND pi.id_institution = i_id_institution
                   AND pi.id_professional = p.id_professional
                   AND nvl(p.flg_prof_test, pk_alert_constant.get_no) = pk_alert_constant.get_no
                   AND (p.name IS NULL OR
                       (translate(lower(p.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND translate(upper(p.name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                   AND (get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market) IS NULL OR
                       (translate(lower(get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(lower(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (p.city IS NULL OR
                       (translate(lower(p.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (p.zip_code IS NULL OR
                       (translate(lower(p.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(lower(i_postal_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')));
            
                SELECT COUNT(DISTINCT stgp.id_stg_professional)
                  INTO l_count_2_stgp
                  FROM stg_professional stgp
                 WHERE stgp.id_institution = i_id_institution
                   AND (stgp.name IS NULL OR
                       (translate(lower(stgp.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND translate(upper(stgp.name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                   AND (get_ext_prof_category(i_lang, NULL, stgp.id_stg_professional, l_id_market) IS NULL OR
                       (translate(lower(get_ext_prof_category(i_lang, NULL, stgp.id_stg_professional, l_id_market)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(lower(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgp.city IS NULL OR
                       (translate(lower(stgp.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgp.zip_code IS NULL OR
                       (translate(lower(stgp.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(lower(i_postal_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND get_ext_prof_license_number(i_lang, NULL, stgp.id_stg_professional, l_id_market) NOT IN
                       (SELECT column_value
                          FROM TABLE(CAST(l_license_array AS table_varchar)));
            END IF;
        
            o_ext_prof_count := l_count_2_p + l_count_2_stgp;
        
        ELSE
        
            IF i_search IS NULL
            THEN
                g_error := 'GET EXT_PROF_LIST CURSOR';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.FIND_EXT_PROF ' || g_error);
                SELECT COUNT(DISTINCT p.id_professional)
                  INTO l_count_3_p1
                  FROM professional p, prof_institution pi
                 WHERE pi.flg_external = pk_alert_constant.get_yes
                   AND pi.flg_state = g_ext_prof_active
                   AND pi.dt_end_tstz IS NULL
                   AND pi.id_institution = i_id_institution
                   AND pi.id_professional = p.id_professional
                   AND nvl(p.flg_prof_test, pk_alert_constant.get_no) = pk_alert_constant.get_no
                   AND (p.name IS NULL OR
                       (translate(lower(p.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market) IS NULL OR
                       (translate(lower(get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(lower(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (p.city IS NULL OR
                       (translate(lower(p.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (p.zip_code IS NULL OR
                       ((translate(lower(p.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       (translate(lower(i_postal_code_from),
                                     ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                     ' aeiouaeiouaeiouaocaeioun% ') || '%'))) OR
                       (p.zip_code IS NULL OR
                       ((translate(lower(p.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       (translate(lower(i_postal_code_to),
                                      ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                      ' aeiouaeiouaeiouaocaeioun% ') || '%')))));
            
                SELECT COUNT(DISTINCT p.id_professional)
                  INTO l_count_3_p2
                  FROM professional p, prof_institution pi
                 WHERE pi.flg_external = pk_alert_constant.get_yes
                   AND pi.flg_state = g_ext_prof_active
                   AND pi.dt_end_tstz IS NULL
                   AND pi.id_institution = i_id_institution
                   AND pi.id_professional = p.id_professional
                   AND nvl(p.flg_prof_test, pk_alert_constant.get_no) = pk_alert_constant.get_no
                   AND (p.name IS NULL OR
                       (translate(lower(p.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market) IS NULL OR
                       (translate(lower(get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(lower(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (p.city IS NULL OR
                       (translate(lower(p.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (p.zip_code IS NULL OR
                       ((translate(lower(p.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') BETWEEN
                       (translate(lower(i_postal_code_from),
                                     ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                     ' aeiouaeiouaeiouaocaeioun% ') || '%') AND
                       (translate(lower(i_postal_code_to),
                                     ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                     ' aeiouaeiouaeiouaocaeioun% ') || '%'))));
            
                SELECT COUNT(DISTINCT stgp.id_stg_professional)
                  INTO l_count_3_stgp1
                  FROM stg_professional stgp
                 WHERE stgp.id_institution = i_id_institution
                   AND (stgp.name IS NULL OR
                       (translate(lower(stgp.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (get_ext_prof_category(i_lang, NULL, stgp.id_stg_professional, l_id_market) IS NULL OR
                       (translate(lower(get_ext_prof_category(i_lang, NULL, stgp.id_stg_professional, l_id_market)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(lower(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgp.city IS NULL OR
                       (translate(lower(stgp.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgp.zip_code IS NULL OR
                       ((translate(lower(stgp.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       (translate(lower(i_postal_code_from),
                                     ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                     ' aeiouaeiouaeiouaocaeioun% ') || '%'))) OR
                       (stgp.zip_code IS NULL OR
                       ((translate(lower(stgp.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       (translate(lower(i_postal_code_to),
                                      ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                      ' aeiouaeiouaeiouaocaeioun% ') || '%')))))
                   AND get_ext_prof_license_number(i_lang, NULL, stgp.id_stg_professional, l_id_market) NOT IN
                       (SELECT column_value
                          FROM TABLE(CAST(l_license_array AS table_varchar)));
            
                SELECT COUNT(DISTINCT stgp.id_stg_professional)
                  INTO l_count_3_stgp2
                  FROM stg_professional stgp
                 WHERE stgp.id_institution = i_id_institution
                   AND (stgp.name IS NULL OR
                       (translate(lower(stgp.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (get_ext_prof_category(i_lang, NULL, stgp.id_stg_professional, l_id_market) IS NULL OR
                       (translate(lower(get_ext_prof_category(i_lang, NULL, stgp.id_stg_professional, l_id_market)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(lower(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgp.city IS NULL OR
                       (translate(lower(stgp.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgp.zip_code IS NULL OR
                       ((translate(lower(stgp.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') BETWEEN
                       (translate(lower(i_postal_code_from),
                                     ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                     ' aeiouaeiouaeiouaocaeioun% ') || '%') AND
                       (translate(lower(i_postal_code_to),
                                     ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                     ' aeiouaeiouaeiouaocaeioun% ') || '%'))))
                   AND get_ext_prof_license_number(i_lang, NULL, stgp.id_stg_professional, l_id_market) NOT IN
                       (SELECT column_value
                          FROM TABLE(CAST(l_license_array AS table_varchar)));
            
            ELSE
            
                g_error := 'GET EXT_PROF_LIST CURSOR';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.FIND_EXT_PROF ' || g_error);
                SELECT COUNT(DISTINCT p.id_professional)
                  INTO l_count_3_p1
                  FROM professional p, prof_institution pi
                 WHERE pi.flg_external = pk_alert_constant.get_yes
                   AND pi.flg_state = g_ext_prof_active
                   AND pi.dt_end_tstz IS NULL
                   AND pi.id_institution = i_id_institution
                   AND pi.id_professional = p.id_professional
                   AND nvl(p.flg_prof_test, pk_alert_constant.get_no) = pk_alert_constant.get_no
                   AND (p.name IS NULL OR
                       (translate(lower(p.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND translate(upper(p.name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                   AND (get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market) IS NULL OR
                       (translate(lower(get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(lower(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (p.city IS NULL OR
                       (translate(lower(p.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (p.zip_code IS NULL OR
                       ((translate(lower(p.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       (translate(lower(i_postal_code_from),
                                     ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                     ' aeiouaeiouaeiouaocaeioun% ') || '%'))) OR
                       (p.zip_code IS NULL OR
                       ((translate(lower(p.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       (translate(lower(i_postal_code_to),
                                      ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                      ' aeiouaeiouaeiouaocaeioun% ') || '%')))));
            
                SELECT COUNT(DISTINCT p.id_professional)
                  INTO l_count_3_p2
                  FROM professional p, prof_institution pi
                 WHERE pi.flg_external = pk_alert_constant.get_yes
                   AND pi.flg_state = g_ext_prof_active
                   AND pi.dt_end_tstz IS NULL
                   AND pi.id_institution = i_id_institution
                   AND pi.id_professional = p.id_professional
                   AND nvl(p.flg_prof_test, pk_alert_constant.get_no) = pk_alert_constant.get_no
                   AND (p.name IS NULL OR
                       (translate(lower(p.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND translate(upper(p.name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                   AND (get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market) IS NULL OR
                       (translate(lower(get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(lower(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (p.city IS NULL OR
                       (translate(lower(p.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (p.zip_code IS NULL OR
                       ((translate(lower(p.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') BETWEEN
                       (translate(lower(i_postal_code_from),
                                     ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                     ' aeiouaeiouaeiouaocaeioun% ') || '%') AND
                       (translate(lower(i_postal_code_to),
                                     ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                     ' aeiouaeiouaeiouaocaeioun% ') || '%'))));
            
                SELECT COUNT(DISTINCT stgp.id_stg_professional)
                  INTO l_count_3_stgp1
                  FROM stg_professional stgp
                 WHERE stgp.id_institution = i_id_institution
                   AND (stgp.name IS NULL OR
                       (translate(lower(stgp.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND translate(upper(stgp.name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                   AND (get_ext_prof_category(i_lang, NULL, stgp.id_stg_professional, l_id_market) IS NULL OR
                       (translate(lower(get_ext_prof_category(i_lang, NULL, stgp.id_stg_professional, l_id_market)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(lower(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgp.city IS NULL OR
                       (translate(lower(stgp.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgp.zip_code IS NULL OR
                       ((translate(lower(stgp.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       (translate(lower(i_postal_code_from),
                                     ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                     ' aeiouaeiouaeiouaocaeioun% ') || '%'))) OR
                       (stgp.zip_code IS NULL OR
                       ((translate(lower(stgp.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       (translate(lower(i_postal_code_to),
                                      ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                      ' aeiouaeiouaeiouaocaeioun% ') || '%')))))
                   AND get_ext_prof_license_number(i_lang, NULL, stgp.id_stg_professional, l_id_market) NOT IN
                       (SELECT column_value
                          FROM TABLE(CAST(l_license_array AS table_varchar)));
            
                SELECT COUNT(DISTINCT stgp.id_stg_professional)
                  INTO l_count_3_stgp2
                  FROM stg_professional stgp
                 WHERE stgp.id_institution = i_id_institution
                   AND (stgp.name IS NULL OR
                       (translate(lower(stgp.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND translate(upper(stgp.name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                   AND (get_ext_prof_category(i_lang, NULL, stgp.id_stg_professional, l_id_market) IS NULL OR
                       (translate(lower(get_ext_prof_category(i_lang, NULL, stgp.id_stg_professional, l_id_market)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(lower(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgp.city IS NULL OR
                       (translate(lower(stgp.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgp.zip_code IS NULL OR
                       ((translate(lower(stgp.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') BETWEEN
                       (translate(lower(i_postal_code_from),
                                     ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                     ' aeiouaeiouaeiouaocaeioun% ') || '%') AND
                       (translate(lower(i_postal_code_to),
                                     ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                     ' aeiouaeiouaeiouaocaeioun% ') || '%'))))
                   AND get_ext_prof_license_number(i_lang, NULL, stgp.id_stg_professional, l_id_market) NOT IN
                       (SELECT column_value
                          FROM TABLE(CAST(l_license_array AS table_varchar)));
            END IF;
        
            o_ext_prof_count := l_count_3_p1 + l_count_3_p2 + l_count_3_stgp1 + l_count_3_stgp2;
        
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
                                              i_function => 'FIND_EXT_PROF_COUNT',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END find_ext_prof_count;

    /********************************************************************************************
    * Find external professionals data
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institutions ID
    * @param i_name                  External professional name
    * @param i_category              External professional Type
    * @param i_city                  External professional City
    * @param i_postal_code           External professional Postal Code
    * @param i_postal_code_from      External professionals range of postal codes
    * @param i_postal_code_to        External professionals range of postal codes
    * @param i_search                Search
    * @param i_start_record          Paging - initial recrod number
    * @param i_num_records           Paging - number of records to display
    * @param o_error                 error    
    *
    *
    * @return                      true or false on success or error
    *
    * @author                        Tércio Soares
    * @since                         2010/06/04
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION find_ext_prof_data
    (
        i_lang             IN language.id_language%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_name             IN professional.name%TYPE,
        i_category         IN VARCHAR2,
        i_city             IN professional.city%TYPE,
        i_postal_code      IN professional.zip_code%TYPE,
        i_postal_code_from IN professional.zip_code%TYPE,
        i_postal_code_to   IN professional.zip_code%TYPE,
        i_search           IN VARCHAR2,
        i_start_record     IN NUMBER DEFAULT 1,
        i_num_records      IN NUMBER DEFAULT get_num_records
    ) RETURN t_table_stg_ext_prof IS
    
        l_date     t_table_stg_ext_prof;
        l_date_res t_table_stg_ext_prof;
    
        l_id_market market.id_market%TYPE;
    
        l_license_array table_varchar := table_varchar();
    
    BEGIN
    
        g_error := 'GET INSTITUTION MARKET';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.FIND_EXT_PROF ' || g_error);
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        g_error := 'GET EXT_PROF LINKED TO INSTITUTION (ID: ' || i_id_institution || ' ) LICENSES';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.FIND_EXT_PROF ' || g_error);
        SELECT license_number
          BULK COLLECT
          INTO l_license_array
          FROM (SELECT DISTINCT get_ext_prof_license_number(i_lang, p.id_professional, NULL, l_id_market) license_number
                  FROM professional p, prof_institution pi
                 WHERE pi.flg_external = pk_alert_constant.get_yes
                   AND pi.flg_state = g_ext_prof_active
                   AND pi.dt_end_tstz IS NULL
                   AND pi.id_institution = i_id_institution
                   AND pi.id_professional = p.id_professional
                   AND nvl(p.flg_prof_test, pk_alert_constant.get_no) = pk_alert_constant.get_no)
         WHERE license_number IS NOT NULL;
    
        IF i_postal_code IS NULL
           AND i_postal_code_from IS NULL
           AND i_postal_code_to IS NULL
        THEN
        
            IF i_search IS NULL
            THEN
            
                g_error := 'GET EXT_PROF_LIST CURSOR';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.FIND_EXT_PROF ' || g_error);
                SELECT t_rec_stg_ext_prof(id_professional, name, zip_code, city, flg_exist)
                  BULK COLLECT
                  INTO l_date
                  FROM (SELECT p.id_professional, p.name, p.zip_code, p.city, pk_alert_constant.get_yes flg_exist
                          FROM professional p, prof_institution pi
                         WHERE pi.flg_external = pk_alert_constant.get_yes
                           AND pi.flg_state = g_ext_prof_active
                           AND pi.dt_end_tstz IS NULL
                           AND pi.id_institution = i_id_institution
                           AND pi.id_professional = p.id_professional
                           AND nvl(p.flg_prof_test, pk_alert_constant.get_no) = pk_alert_constant.get_no
                           AND (p.name IS NULL OR
                               (translate(lower(p.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market) IS NULL OR
                               (translate(lower(get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(lower(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (p.city IS NULL OR
                               (translate(lower(p.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                        UNION
                        SELECT stgp.id_stg_professional id_professional,
                               stgp.name,
                               stgp.zip_code,
                               stgp.city,
                               pk_alert_constant.get_no flg_exist
                          FROM stg_professional stgp
                         WHERE stgp.id_institution = i_id_institution
                           AND (stgp.name IS NULL OR
                               (translate(lower(stgp.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (get_ext_prof_category(i_lang, NULL, stgp.id_stg_professional, l_id_market) IS NULL OR
                               (translate(lower(get_ext_prof_category(i_lang,
                                                                       NULL,
                                                                       stgp.id_stg_professional,
                                                                       l_id_market)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(lower(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgp.city IS NULL OR
                               (translate(lower(stgp.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND get_ext_prof_license_number(i_lang, NULL, stgp.id_stg_professional, l_id_market) NOT IN
                               (SELECT column_value
                                  FROM TABLE(CAST(l_license_array AS table_varchar)))
                         ORDER BY flg_exist DESC, name, city, zip_code);
            
            ELSE
            
                g_error := 'GET EXT_PROF_LIST CURSOR';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.FIND_EXT_PROF ' || g_error);
                SELECT t_rec_stg_ext_prof(id_professional, name, zip_code, city, flg_exist)
                  BULK COLLECT
                  INTO l_date
                  FROM (SELECT p.id_professional, p.name, p.zip_code, p.city, pk_alert_constant.get_yes flg_exist
                          FROM professional p, prof_institution pi
                         WHERE pi.flg_external = pk_alert_constant.get_yes
                           AND pi.flg_state = g_ext_prof_active
                           AND pi.dt_end_tstz IS NULL
                           AND pi.id_institution = i_id_institution
                           AND pi.id_professional = p.id_professional
                           AND nvl(p.flg_prof_test, pk_alert_constant.get_no) = pk_alert_constant.get_no
                           AND (p.name IS NULL OR
                               (translate(lower(p.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND translate(upper(p.name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                               '%' ||
                               translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                           AND (get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market) IS NULL OR
                               (translate(lower(get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(lower(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (p.city IS NULL OR
                               (translate(lower(p.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                        UNION
                        SELECT stgp.id_stg_professional id_professional,
                               stgp.name,
                               stgp.zip_code,
                               stgp.city,
                               pk_alert_constant.get_no flg_exist
                          FROM stg_professional stgp
                         WHERE stgp.id_institution = i_id_institution
                           AND (stgp.name IS NULL OR
                               (translate(lower(stgp.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND translate(upper(stgp.name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                               '%' ||
                               translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                           AND (get_ext_prof_category(i_lang, NULL, stgp.id_stg_professional, l_id_market) IS NULL OR
                               (translate(lower(get_ext_prof_category(i_lang,
                                                                       NULL,
                                                                       stgp.id_stg_professional,
                                                                       l_id_market)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(lower(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgp.city IS NULL OR
                               (translate(lower(stgp.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND get_ext_prof_license_number(i_lang, NULL, stgp.id_stg_professional, l_id_market) NOT IN
                               (SELECT column_value
                                  FROM TABLE(CAST(l_license_array AS table_varchar)))
                         ORDER BY flg_exist DESC, name, city, zip_code);
            
            END IF;
        
        ELSIF i_postal_code IS NOT NULL
        THEN
        
            IF i_search IS NULL
            THEN
            
                g_error := 'GET EXT_PROF_LIST CURSOR';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.FIND_EXT_PROF ' || g_error);
                SELECT t_rec_stg_ext_prof(id_professional, name, zip_code, city, flg_exist)
                  BULK COLLECT
                  INTO l_date
                  FROM (SELECT DISTINCT p.id_professional,
                                        p.name,
                                        p.zip_code,
                                        p.city,
                                        pk_alert_constant.get_yes flg_exist
                          FROM professional p, prof_institution pi
                         WHERE pi.flg_external = pk_alert_constant.get_yes
                           AND pi.flg_state = g_ext_prof_active
                           AND pi.dt_end_tstz IS NULL
                           AND pi.id_institution = i_id_institution
                           AND pi.id_professional = p.id_professional
                           AND nvl(p.flg_prof_test, pk_alert_constant.get_no) = pk_alert_constant.get_no
                           AND (p.name IS NULL OR
                               (translate(lower(p.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market) IS NULL OR
                               (translate(lower(get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(lower(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (p.city IS NULL OR
                               (translate(lower(p.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (p.zip_code IS NULL OR
                               (translate(lower(p.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(lower(i_postal_code),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                        UNION
                        SELECT stgp.id_stg_professional id_professional,
                               stgp.name,
                               stgp.zip_code,
                               stgp.city,
                               pk_alert_constant.get_no flg_exist
                          FROM stg_professional stgp
                         WHERE stgp.id_institution = i_id_institution
                           AND (stgp.name IS NULL OR
                               (translate(lower(stgp.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (get_ext_prof_category(i_lang, NULL, stgp.id_stg_professional, l_id_market) IS NULL OR
                               (translate(lower(get_ext_prof_category(i_lang,
                                                                       NULL,
                                                                       stgp.id_stg_professional,
                                                                       l_id_market)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(lower(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgp.city IS NULL OR
                               (translate(lower(stgp.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgp.zip_code IS NULL OR
                               (translate(lower(stgp.zip_code),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(lower(i_postal_code),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND get_ext_prof_license_number(i_lang, NULL, stgp.id_stg_professional, l_id_market) NOT IN
                               (SELECT column_value
                                  FROM TABLE(CAST(l_license_array AS table_varchar)))
                         ORDER BY flg_exist DESC, name, city, zip_code);
            
            ELSE
            
                g_error := 'GET EXT_PROF_LIST CURSOR';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.FIND_EXT_PROF ' || g_error);
                SELECT t_rec_stg_ext_prof(id_professional, name, zip_code, city, flg_exist)
                  BULK COLLECT
                  INTO l_date
                  FROM (SELECT DISTINCT p.id_professional,
                                        p.name,
                                        p.zip_code,
                                        p.city,
                                        pk_alert_constant.get_yes flg_exist
                          FROM professional p, prof_institution pi
                         WHERE pi.flg_external = pk_alert_constant.get_yes
                           AND pi.flg_state = g_ext_prof_active
                           AND pi.dt_end_tstz IS NULL
                           AND pi.id_institution = i_id_institution
                           AND pi.id_professional = p.id_professional
                           AND nvl(p.flg_prof_test, pk_alert_constant.get_no) = pk_alert_constant.get_no
                           AND (p.name IS NULL OR
                               (translate(lower(p.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND translate(upper(p.name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                               '%' ||
                               translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                           AND (get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market) IS NULL OR
                               (translate(lower(get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(lower(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (p.city IS NULL OR
                               (translate(lower(p.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (p.zip_code IS NULL OR
                               (translate(lower(p.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(lower(i_postal_code),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                        UNION
                        SELECT stgp.id_stg_professional id_professional,
                               stgp.name,
                               stgp.zip_code,
                               stgp.city,
                               pk_alert_constant.get_no flg_exist
                          FROM stg_professional stgp
                         WHERE stgp.id_institution = i_id_institution
                           AND (stgp.name IS NULL OR
                               (translate(lower(stgp.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND translate(upper(stgp.name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                               '%' ||
                               translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                           AND (get_ext_prof_category(i_lang, NULL, stgp.id_stg_professional, l_id_market) IS NULL OR
                               (translate(lower(get_ext_prof_category(i_lang,
                                                                       NULL,
                                                                       stgp.id_stg_professional,
                                                                       l_id_market)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(lower(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgp.city IS NULL OR
                               (translate(lower(stgp.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgp.zip_code IS NULL OR
                               (translate(lower(stgp.zip_code),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(lower(i_postal_code),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND get_ext_prof_license_number(i_lang, NULL, stgp.id_stg_professional, l_id_market) NOT IN
                               (SELECT column_value
                                  FROM TABLE(CAST(l_license_array AS table_varchar)))
                         ORDER BY flg_exist DESC, name, city, zip_code);
            
            END IF;
        ELSE
        
            IF i_search IS NULL
            THEN
            
                g_error := 'GET EXT_PROF_LIST CURSOR';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.FIND_EXT_PROF ' || g_error);
            
                SELECT t_rec_stg_ext_prof(id_professional, name, zip_code, city, flg_exist)
                  BULK COLLECT
                  INTO l_date
                  FROM (SELECT DISTINCT p.id_professional,
                                        p.name,
                                        p.zip_code,
                                        p.city,
                                        pk_alert_constant.get_yes flg_exist
                          FROM professional p, prof_institution pi
                         WHERE pi.flg_external = pk_alert_constant.get_yes
                           AND pi.flg_state = g_ext_prof_active
                           AND pi.dt_end_tstz IS NULL
                           AND pi.id_institution = i_id_institution
                           AND pi.id_professional = p.id_professional
                           AND nvl(p.flg_prof_test, pk_alert_constant.get_no) = pk_alert_constant.get_no
                           AND (p.name IS NULL OR
                               (translate(lower(p.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market) IS NULL OR
                               (translate(lower(get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(lower(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (p.city IS NULL OR
                               (translate(lower(p.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (p.zip_code IS NULL OR
                               ((translate(lower(p.zip_code),
                                            ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                            ' aeiouaeiouaeiouaocaeioun ') LIKE
                               (translate(lower(i_postal_code_from),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun% ') || '%'))) OR
                               (p.zip_code IS NULL OR
                               ((translate(lower(p.zip_code),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun ') LIKE
                               (translate(lower(i_postal_code_to),
                                              ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                              ' aeiouaeiouaeiouaocaeioun% ') || '%')))))
                        
                        UNION
                        SELECT DISTINCT p.id_professional,
                                        p.name,
                                        p.zip_code,
                                        p.city,
                                        pk_alert_constant.get_yes flg_exist
                          FROM professional p, prof_institution pi
                         WHERE pi.flg_external = pk_alert_constant.get_yes
                           AND pi.flg_state = g_ext_prof_active
                           AND pi.dt_end_tstz IS NULL
                           AND pi.id_institution = i_id_institution
                           AND pi.id_professional = p.id_professional
                           AND nvl(p.flg_prof_test, pk_alert_constant.get_no) = pk_alert_constant.get_no
                           AND (p.name IS NULL OR
                               (translate(lower(p.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market) IS NULL OR
                               (translate(lower(get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(lower(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (p.city IS NULL OR
                               (translate(lower(p.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (p.zip_code IS NULL OR
                               ((translate(lower(p.zip_code),
                                            ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                            ' aeiouaeiouaeiouaocaeioun ') BETWEEN
                               (translate(lower(i_postal_code_from),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun% ') || '%') AND
                               (translate(lower(i_postal_code_to),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun% ') || '%'))))
                        UNION
                        SELECT stgp.id_stg_professional id_professional,
                               stgp.name,
                               stgp.zip_code,
                               stgp.city,
                               pk_alert_constant.get_no flg_exist
                          FROM stg_professional stgp
                         WHERE stgp.id_institution = i_id_institution
                           AND (stgp.name IS NULL OR
                               (translate(lower(stgp.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (get_ext_prof_category(i_lang, NULL, stgp.id_stg_professional, l_id_market) IS NULL OR
                               (translate(lower(get_ext_prof_category(i_lang,
                                                                       NULL,
                                                                       stgp.id_stg_professional,
                                                                       l_id_market)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(lower(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgp.city IS NULL OR
                               (translate(lower(stgp.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgp.zip_code IS NULL OR
                               ((translate(lower(stgp.zip_code),
                                            ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                            ' aeiouaeiouaeiouaocaeioun ') LIKE
                               (translate(lower(i_postal_code_from),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun% ') || '%'))) OR
                               (stgp.zip_code IS NULL OR
                               ((translate(lower(stgp.zip_code),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun ') LIKE
                               (translate(lower(i_postal_code_to),
                                              ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                              ' aeiouaeiouaeiouaocaeioun% ') || '%')))))
                           AND get_ext_prof_license_number(i_lang, NULL, stgp.id_stg_professional, l_id_market) NOT IN
                               (SELECT column_value
                                  FROM TABLE(CAST(l_license_array AS table_varchar)))
                        UNION
                        SELECT stgp.id_stg_professional id_professional,
                               stgp.name,
                               stgp.zip_code,
                               stgp.city,
                               pk_alert_constant.get_no flg_exist
                          FROM stg_professional stgp
                         WHERE stgp.id_institution = i_id_institution
                           AND (stgp.name IS NULL OR
                               (translate(lower(stgp.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (get_ext_prof_category(i_lang, NULL, stgp.id_stg_professional, l_id_market) IS NULL OR
                               (translate(lower(get_ext_prof_category(i_lang,
                                                                       NULL,
                                                                       stgp.id_stg_professional,
                                                                       l_id_market)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(lower(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgp.city IS NULL OR
                               (translate(lower(stgp.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgp.zip_code IS NULL OR
                               ((translate(lower(stgp.zip_code),
                                            ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                            ' aeiouaeiouaeiouaocaeioun ') BETWEEN
                               (translate(lower(i_postal_code_from),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun% ') || '%') AND
                               (translate(lower(i_postal_code_to),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun% ') || '%'))))
                           AND get_ext_prof_license_number(i_lang, NULL, stgp.id_stg_professional, l_id_market) NOT IN
                               (SELECT column_value
                                  FROM TABLE(CAST(l_license_array AS table_varchar))))
                 ORDER BY flg_exist DESC, name, city, zip_code;
            
            ELSE
            
                g_error := 'GET EXT_PROF_LIST CURSOR';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.FIND_EXT_PROF ' || g_error);
            
                SELECT t_rec_stg_ext_prof(id_professional, name, zip_code, city, flg_exist)
                  BULK COLLECT
                  INTO l_date
                  FROM (SELECT DISTINCT p.id_professional,
                                        p.name,
                                        p.zip_code,
                                        p.city,
                                        pk_alert_constant.get_yes flg_exist
                          FROM professional p, prof_institution pi
                         WHERE pi.flg_external = pk_alert_constant.get_yes
                           AND pi.flg_state = g_ext_prof_active
                           AND pi.dt_end_tstz IS NULL
                           AND pi.id_institution = i_id_institution
                           AND pi.id_professional = p.id_professional
                           AND nvl(p.flg_prof_test, pk_alert_constant.get_no) = pk_alert_constant.get_no
                           AND (p.name IS NULL OR
                               (translate(lower(p.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND translate(upper(p.name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                               '%' ||
                               translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                           AND (get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market) IS NULL OR
                               (translate(lower(get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(lower(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (p.city IS NULL OR
                               (translate(lower(p.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (p.zip_code IS NULL OR
                               ((translate(lower(p.zip_code),
                                            ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                            ' aeiouaeiouaeiouaocaeioun ') LIKE
                               (translate(lower(i_postal_code_from),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun% ') || '%'))) OR
                               (p.zip_code IS NULL OR
                               ((translate(lower(p.zip_code),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun ') LIKE
                               (translate(lower(i_postal_code_to),
                                              ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                              ' aeiouaeiouaeiouaocaeioun% ') || '%')))))
                        
                        UNION
                        SELECT DISTINCT p.id_professional,
                                        p.name,
                                        p.zip_code,
                                        p.city,
                                        pk_alert_constant.get_yes flg_exist
                          FROM professional p, prof_institution pi
                         WHERE pi.flg_external = pk_alert_constant.get_yes
                           AND pi.flg_state = g_ext_prof_active
                           AND pi.dt_end_tstz IS NULL
                           AND pi.id_institution = i_id_institution
                           AND pi.id_professional = p.id_professional
                           AND nvl(p.flg_prof_test, pk_alert_constant.get_no) = pk_alert_constant.get_no
                           AND (p.name IS NULL OR
                               (translate(lower(p.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND translate(upper(p.name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                               '%' ||
                               translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                           AND (get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market) IS NULL OR
                               (translate(lower(get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(lower(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (p.city IS NULL OR
                               (translate(lower(p.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (p.zip_code IS NULL OR
                               ((translate(lower(p.zip_code),
                                            ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                            ' aeiouaeiouaeiouaocaeioun ') BETWEEN
                               (translate(lower(i_postal_code_from),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun% ') || '%') AND
                               (translate(lower(i_postal_code_to),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun% ') || '%'))))
                        UNION
                        SELECT stgp.id_stg_professional id_professional,
                               stgp.name,
                               stgp.zip_code,
                               stgp.city,
                               pk_alert_constant.get_no flg_exist
                          FROM stg_professional stgp
                         WHERE stgp.id_institution = i_id_institution
                           AND (stgp.name IS NULL OR
                               (translate(lower(stgp.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND translate(upper(stgp.name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                               '%' ||
                               translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                           AND (get_ext_prof_category(i_lang, NULL, stgp.id_stg_professional, l_id_market) IS NULL OR
                               (translate(lower(get_ext_prof_category(i_lang,
                                                                       NULL,
                                                                       stgp.id_stg_professional,
                                                                       l_id_market)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(lower(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgp.city IS NULL OR
                               (translate(lower(stgp.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgp.zip_code IS NULL OR
                               ((translate(lower(stgp.zip_code),
                                            ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                            ' aeiouaeiouaeiouaocaeioun ') LIKE
                               (translate(lower(i_postal_code_from),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun% ') || '%'))) OR
                               (stgp.zip_code IS NULL OR
                               ((translate(lower(stgp.zip_code),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun ') LIKE
                               (translate(lower(i_postal_code_to),
                                              ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                              ' aeiouaeiouaeiouaocaeioun% ') || '%')))))
                           AND get_ext_prof_license_number(i_lang, NULL, stgp.id_stg_professional, l_id_market) NOT IN
                               (SELECT column_value
                                  FROM TABLE(CAST(l_license_array AS table_varchar)))
                        UNION
                        SELECT stgp.id_stg_professional id_professional,
                               stgp.name,
                               stgp.zip_code,
                               stgp.city,
                               pk_alert_constant.get_no flg_exist
                          FROM stg_professional stgp
                         WHERE stgp.id_institution = i_id_institution
                           AND (stgp.name IS NULL OR
                               (translate(lower(stgp.name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND translate(upper(stgp.name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                               '%' ||
                               translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                           AND (get_ext_prof_category(i_lang, NULL, stgp.id_stg_professional, l_id_market) IS NULL OR
                               (translate(lower(get_ext_prof_category(i_lang,
                                                                       NULL,
                                                                       stgp.id_stg_professional,
                                                                       l_id_market)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(lower(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgp.city IS NULL OR
                               (translate(lower(stgp.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(lower(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgp.zip_code IS NULL OR
                               ((translate(lower(stgp.zip_code),
                                            ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                            ' aeiouaeiouaeiouaocaeioun ') BETWEEN
                               (translate(lower(i_postal_code_from),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun% ') || '%') AND
                               (translate(lower(i_postal_code_to),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun% ') || '%'))))
                           AND get_ext_prof_license_number(i_lang, NULL, stgp.id_stg_professional, l_id_market) NOT IN
                               (SELECT column_value
                                  FROM TABLE(CAST(l_license_array AS table_varchar))))
                 ORDER BY flg_exist DESC, name, city, zip_code;
            
            END IF;
        
        END IF;
    
        g_error := 'GET EXT_PROF TABLE FROM RECORD: ' || to_char(i_start_record) || ' TO RECORD: ' ||
                   to_char(i_start_record + i_num_records - 1);
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_LIST_DATA ' || g_error);
        SELECT t_rec_stg_ext_prof(id_professional, name, zip_code, city, flg_exist)
          BULK COLLECT
          INTO l_date_res
          FROM (SELECT rownum rn, t.*
                  FROM TABLE(CAST(l_date AS t_table_stg_ext_prof)) t)
         WHERE rn BETWEEN i_start_record AND i_start_record + i_num_records - 1;
    
        RETURN l_date_res;
    
    END find_ext_prof_data;

    /********************************************************************************************
    * Find external professionals
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institutions ID
    * @param i_name                  External professional name
    * @param i_category              External professional Type
    * @param i_city                  External professional City
    * @param i_postal_code           External professional Postal Code
    * @param i_postal_code_from      External professionals range of postal codes
    * @param i_postal_code_to        External professionals range of postal codes
    * @param i_search                Search
    * @param i_start_record          Paging - initial recrod number
    * @param i_num_records           Paging - number of records to display
    * @param o_ext_prof_list         List of external professionals
    * @param o_error                 error    
    *
    *
    * @return                      true or false on success or error
    *
    * @author                        Tércio Soares
    * @since                         2010/06/03
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION find_ext_prof
    (
        i_lang             IN language.id_language%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_name             IN professional.name%TYPE,
        i_category         IN VARCHAR2,
        i_city             IN professional.city%TYPE,
        i_postal_code      IN professional.zip_code%TYPE,
        i_postal_code_from IN professional.zip_code%TYPE,
        i_postal_code_to   IN professional.zip_code%TYPE,
        i_search           IN VARCHAR2,
        i_start_record     IN NUMBER DEFAULT 1,
        i_num_records      IN NUMBER DEFAULT get_num_records,
        o_ext_prof_list    OUT pk_types.cursor_type,
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
    
        g_error := 'GET EXT_PROF_LIST CURSOR';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.FIND_EXT_PROF ' || g_error);
        OPEN o_ext_prof_list FOR
            SELECT DISTINCT id_professional,
                            pk_backoffice.get_prof_photo_url(i_lang, id_professional) photo_url,
                            name,
                            decode(flg_exist,
                                   pk_alert_constant.get_yes,
                                   get_ext_prof_category(i_lang, id_professional, NULL, l_id_market),
                                   get_ext_prof_category(i_lang, NULL, id_professional, l_id_market)) category,
                            decode(flg_exist,
                                   pk_alert_constant.get_yes,
                                   get_ext_prof_license_number(i_lang, id_professional, NULL, l_id_market),
                                   get_ext_prof_license_number(i_lang, NULL, id_professional, l_id_market)) license_number,
                            zip_code,
                            city,
                            flg_exist
              FROM (SELECT *
                      FROM TABLE(find_ext_prof_data(i_lang,
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
             ORDER BY flg_exist DESC, name;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'FIND_EXT_PROF',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_ext_prof_list);
            RETURN FALSE;
        
    END find_ext_prof;

    /********************************************************************************************
    * Update/insert information for an external user
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
    FUNCTION set_import_ext_professionals
    (
        i_lang             IN language.id_language%TYPE,
        i_stg_professional IN table_number,
        i_id_institution   IN institution.id_institution%TYPE,
        o_ext_prof         OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(100) := 'SET_IMPORT_EXT_PROFESSIONALS';
    
        l_id_country country.id_country%TYPE;
        l_id_market  market.id_market%TYPE;
        l_exception EXCEPTION;
        l_error    t_error_out;
        l_index    NUMBER := 1;
        l_index_pi NUMBER := 1;
    
        --EXTERNAL PROFESSIONAL
        l_id_professional professional.id_professional%TYPE;
        l_title           professional.title%TYPE;
        l_first_name      professional.first_name%TYPE;
        l_middle_name     professional.middle_name%TYPE;
        l_last_name       professional.last_name%TYPE;
        l_initials        professional.initials%TYPE;
        l_dt_birth        professional.dt_birth%TYPE;
        l_gender          professional.gender%TYPE;
        l_street          professional.address%TYPE;
        l_zip_code        professional.zip_code%TYPE;
        l_city            professional.city%TYPE;
        l_phone           professional.num_contact%TYPE;
        l_cell_phone      professional.cell_phone%TYPE;
        l_fax             professional.fax%TYPE;
        l_email           professional.email%TYPE;
        l_num_order       professional.num_order%TYPE;
    
        --EXTERNAL PROF_INSTITUTION
        l_stg_id_institution stg_prof_institution.id_stg_institution%TYPE;
        l_stg_flg_state      stg_prof_institution.flg_state%TYPE;
        l_stg_dt_begin       stg_prof_institution.dt_begin_tstz%TYPE;
        l_stg_dt_end         stg_prof_institution.dt_end_tstz%TYPE;
        l_id_institution     institution.id_institution%TYPE;
        l_institution_list   table_number := table_number();
        l_state_list         table_varchar := table_varchar();
        l_dt_begin_list      table_varchar := table_varchar();
        l_dt_end_list        table_varchar := table_varchar();
    
        --PROFESSIONAL_FIELDS_DATA
        l_fields       table_number := table_number();
        l_values       table_varchar := table_varchar();
        l_institutions table_number := table_number();
    
        CURSOR c_ext_prof(c_id_stg_professional IN stg_professional.id_stg_professional%TYPE) IS
            SELECT stgp.title,
                   stgp.first_name,
                   stgp.middle_name,
                   stgp.last_name,
                   stgp.initials,
                   stgp.dt_birth,
                   stgp.gender,
                   stgp.address,
                   stgp.zip_code,
                   stgp.city,
                   stgp.num_contact,
                   stgp.cell_phone,
                   stgp.fax,
                   stgp.email,
                   stgp.num_order
              FROM stg_professional stgp
             WHERE stgp.id_stg_professional = c_id_stg_professional
               AND stgp.id_institution = i_id_institution;
    
        CURSOR c_ext_prof_inst(c_id_stg_professional IN stg_professional.id_stg_professional%TYPE) IS
            SELECT stgpi.id_stg_institution, stgpi.flg_state, stgpi.dt_begin_tstz, stgpi.dt_end_tstz
              FROM stg_prof_institution stgpi
             WHERE stgpi.id_stg_professional = c_id_stg_professional
               AND stgpi.id_institution = i_id_institution;
        l_prof_institution prof_institution.id_prof_institution%TYPE := 0;
    
        CURSOR c_inst(i_id_professional professional.id_professional%TYPE) IS
            SELECT p_inst.id_prof_institution
              FROM (SELECT x.*
                      FROM prof_institution x
                     WHERE x.id_institution = i_id_institution
                       AND x.id_professional = i_id_professional
                     ORDER BY x.dt_end_tstz DESC) p_inst
             WHERE rownum = 1;
        l_inst prof_institution.id_prof_institution%TYPE := NULL;
    BEGIN
    
        o_ext_prof := table_number();
    
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   g_market_all)
          INTO l_id_market
          FROM dual;
    
        SELECT nvl((SELECT ia.id_country
                     FROM inst_attributes ia
                    WHERE ia.id_institution = i_id_institution),
                   -1)
          INTO l_id_country
          FROM dual;
    
        FOR i IN 1 .. i_stg_professional.count
        LOOP
        
            g_error := 'GET EXT_PROF FIELDS TO INSTITUTION (ID: ' || i_id_institution || ' ) MARKET (ID_MARKET: ' ||
                       l_id_market || ' )';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.SET_IMPORT_EXT_PROFESSIONALS ' || g_error);
            SELECT fm.id_field_market, stgpd.value, 0
              BULK COLLECT
              INTO l_fields, l_values, l_institutions
              FROM field f, field_market fm, stg_professional_field_data stgpd
             WHERE f.flg_field_prof_inst = g_field_flg_pi_prof
               AND f.flg_available = pk_alert_constant.get_available
               AND f.id_field_type IN (g_field_type_personal_data,
                                       g_field_type_personal_contacts,
                                       g_field_type_prof_data,
                                       g_field_type_inst_data)
               AND f.id_field = fm.id_field
               AND fm.id_market = l_id_market
               AND fm.flg_available = pk_alert_constant.get_available
               AND stgpd.id_stg_professional = i_stg_professional(i)
               AND stgpd.id_institution = i_id_institution
               AND stgpd.id_field = f.id_field;
        
            OPEN c_ext_prof(i_stg_professional(i));
            LOOP
            
                g_error := 'GET EXT_PROF DATA (ID_STG_PROFESSIONAL: ' || i_id_institution || ' ) MARKET (ID_MARKET: ' ||
                           l_id_market || ' )';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.SET_IMPORT_EXT_PROFESSIONALS ' || g_error);
                FETCH c_ext_prof
                    INTO l_title,
                         l_first_name,
                         l_middle_name,
                         l_last_name,
                         l_initials,
                         l_dt_birth,
                         l_gender,
                         l_street,
                         l_zip_code,
                         l_city,
                         l_phone,
                         l_cell_phone,
                         l_fax,
                         l_email,
                         l_num_order;
                EXIT WHEN c_ext_prof%NOTFOUND;
            
                IF NOT set_ext_professional(i_lang            => i_lang,
                                            i_id_professional => NULL,
                                            i_title           => l_title,
                                            i_first_name      => l_first_name,
                                            i_middle_name     => l_middle_name,
                                            i_last_name       => l_last_name,
                                            i_initials        => l_initials,
                                            i_dt_birth        => pk_backoffice.get_date_to_be_sent(i_lang, l_dt_birth),
                                            i_gender          => l_gender,
                                            i_street          => l_street,
                                            i_zip_code        => l_zip_code,
                                            i_city            => l_city,
                                            i_id_country      => l_id_country,
                                            i_phone           => l_phone,
                                            i_cell_phone      => l_cell_phone,
                                            i_fax             => l_fax,
                                            i_email           => l_email,
                                            i_num_order       => l_num_order,
                                            i_speciality      => NULL,
                                            i_id_institution  => i_id_institution,
                                            i_fields          => l_fields,
                                            i_institution     => l_institutions,
                                            i_values          => l_values,
                                            o_professional    => l_id_professional,
                                            o_error           => l_error)
                THEN
                    RAISE l_exception;
                
                ELSE
                    OPEN c_inst(l_id_professional);
                    LOOP
                        FETCH c_inst
                            INTO l_inst;
                        EXIT WHEN c_inst%NOTFOUND;
                    
                        pk_api_ab_tables.upd_ins_into_prof_institution(i_id_prof_institution => l_inst,
                                                                       i_id_professional     => l_id_professional,
                                                                       i_id_institution      => i_id_institution,
                                                                       i_flg_external        => pk_alert_constant.get_yes,
                                                                       i_dn_flg_status       => g_prof_inst_dn_validated,
                                                                       o_id_prof_institution => l_prof_institution);
                        l_inst := NULL;
                    END LOOP;
                    CLOSE c_inst;
                    l_index_pi := 1;
                    OPEN c_ext_prof_inst(i_stg_professional(i));
                    LOOP
                    
                        g_error := 'GET EXT_PROF_INST DATA (ID_STG_PROFESSIONAL: ' || i_id_institution ||
                                   ' ) MARKET (ID_MARKET: ' || l_id_market || ' )';
                        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.SET_IMPORT_EXT_PROFESSIONALS ' || g_error);
                        FETCH c_ext_prof_inst
                            INTO l_stg_id_institution, l_stg_flg_state, l_stg_dt_begin, l_stg_dt_end;
                        EXIT WHEN c_ext_prof_inst%NOTFOUND;
                    
                        CASE l_id_market
                            WHEN g_market_nl THEN
                            
                                SELECT nvl((SELECT ifd.id_institution
                                             FROM institution_field_data ifd, field_market fm
                                            WHERE ifd.value =
                                                  pk_backoffice_ext_instit.get_ext_inst_license_number(i_lang,
                                                                                                       NULL,
                                                                                                       l_stg_id_institution,
                                                                                                       l_id_market)
                                              AND ifd.id_field_market = fm.id_field_market
                                              AND fm.id_field = g_field_inst_agb
                                              AND fm.id_market = l_id_market
                                              AND rownum = 1),
                                           pk_alert_constant.g_inst_all)
                                  INTO l_id_institution
                                  FROM dual;
                            
                            ELSE
                                l_id_institution := pk_alert_constant.g_inst_all;
                        END CASE;
                    
                        IF l_id_institution != pk_alert_constant.g_inst_all
                        THEN
                        
                            l_institution_list.extend;
                            l_state_list.extend;
                            l_dt_begin_list.extend;
                            l_dt_end_list.extend;
                        
                            l_institution_list(l_index_pi) := l_id_institution;
                            l_state_list(l_index_pi) := l_stg_flg_state;
                            l_dt_begin_list(l_index_pi) := pk_date_utils.date_send_tsz(i_lang,
                                                                                       l_stg_dt_begin,
                                                                                       profissional(g_prof_backoffice,
                                                                                                    i_id_institution,
                                                                                                    g_soft_backoffice));
                            l_dt_end_list(l_index_pi) := pk_date_utils.date_send_tsz(i_lang,
                                                                                     l_stg_dt_end,
                                                                                     profissional(g_prof_backoffice,
                                                                                                  i_id_institution,
                                                                                                  g_soft_backoffice));
                        
                        END IF;
                    
                    END LOOP;
                
                    CLOSE c_ext_prof_inst;
                
                    IF NOT set_ext_prof_institution(i_lang            => i_lang,
                                                    i_prof            => profissional(g_prof_backoffice,
                                                                                      i_id_institution,
                                                                                      g_soft_backoffice),
                                                    i_id_professional => l_id_professional,
                                                    i_institution     => l_institution_list,
                                                    i_dt_begin        => l_dt_begin_list,
                                                    i_dt_end          => l_dt_end_list,
                                                    i_flg_state       => l_state_list,
                                                    i_inst_delete     => table_number(),
                                                    o_error           => l_error)
                    THEN
                        RAISE l_exception;
                    
                    END IF;
                
                    o_ext_prof.extend;
                
                    o_ext_prof(l_index) := l_id_professional;
                
                    l_index := l_index + 1;
                END IF;
            
            END LOOP;
        
            CLOSE c_ext_prof;
        
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
                                              i_function => l_func_name,
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_import_ext_professionals;

    /********************************************************************************************
    * Validate Insitution External Professionals take over dates
    *
    * @param i_lang                 Language id
    * @param i_id_institution       Institution identifier
    * @param o_error                Error message
    *
    * @return                       true (sucess), false (error)
    *
    * @author                       Tércio Soares
    * @since                        2010/06/03
    * @version                      2.6.0.3
    ********************************************************************************************/
    FUNCTION validate_ext_prof_to
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'VALIDATE INSTITUTION ID = ' || i_id_institution || ' EXT_PROFESSIONALS TAKE OVER DATE < ' ||
                   current_timestamp;
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.VALIDATE_EXT_PROF_TO ' || g_error);
        UPDATE professional_take_over pto
           SET pto.flg_status = g_ext_prof_to_finished
         WHERE pto.id_professional_from IN
               (SELECT pi.id_professional
                  FROM prof_institution pi
                 WHERE pi.id_institution = i_id_institution
                   AND pi.dt_end_tstz IS NULL
                   AND pi.flg_state = g_ext_prof_active
                   AND pi.flg_external = pk_alert_constant.get_yes)
           AND pto.flg_status = g_ext_prof_to_sch
           AND pto.take_over_time < current_timestamp;
    
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
                                              i_function => 'VALIDATE_EXT_PROF_TO',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END validate_ext_prof_to;

    /********************************************************************************************
    * Validate External Professionals take overs scheduled
    *
    * @param i_lang                  Language id
    * @param i_id_professional_to    External Professional identifier
    *
    * @return                       true ('Y'), false ('N')
    *
    * @author                       Tércio Soares
    * @since                        2010/06/04
    * @version                      2.6.0.3
    ********************************************************************************************/
    FUNCTION verifiy_ext_prof_to_possible
    (
        i_lang               IN language.id_language%TYPE,
        i_id_professional_to IN professional_take_over.id_professional_to%TYPE
    ) RETURN VARCHAR2 IS
    
        l_count_s NUMBER := 0;
        l_count_f NUMBER := 0;
    
        l_error t_error_out;
    
    BEGIN
        g_error := 'VALIDATE EXTERNAL PROFESSIONAL SCHEDULED TAKE OVER';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.VALIDATE_EXT_PROF_TO_POSSIBLE ' || g_error);
        SELECT COUNT(*)
          INTO l_count_s
          FROM professional_take_over pto
         WHERE pto.id_professional_to = i_id_professional_to
           AND pto.flg_status = g_ext_prof_to_sch;
    
        g_error := 'VALIDATE EXTERNAL PROFESSIONAL CONCLUDED TAKE OVER';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.VALIDATE_EXT_PROF_TO_POSSIBLE ' || g_error);
        SELECT COUNT(*)
          INTO l_count_f
          FROM professional_take_over pto
         WHERE pto.id_professional_from = i_id_professional_to
           AND pto.flg_status = g_ext_prof_to_finished;
    
        IF l_count_s = 0
           AND l_count_f = 0
        THEN
            RETURN pk_alert_constant.get_yes;
        ELSE
            RETURN pk_alert_constant.get_no;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'VALIDATE_EXT_PROF_TO_POSSIBLE',
                                              o_error    => l_error);
            RETURN pk_alert_constant.get_no;
    END verifiy_ext_prof_to_possible;

    /********************************************************************************************
    * Set the External Professional take over
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional (id, institution, software)
    * @param i_id_professional_from  External professional take over from id
    * @param i_id_professional_to    External professional take over to id
    * @param i_take_over_time        Take Over defined Time
    * @param i_notes                 Take Over notes
    * @param o_flg_status            Take over status
    * @param o_status_desc           Description of Take over status
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/03
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION set_ext_prof_to
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_professional_from IN professional_take_over.id_professional_from%TYPE,
        i_id_professional_to   IN professional_take_over.id_professional_to%TYPE,
        i_take_over_time       IN VARCHAR2,
        i_notes                IN professional_take_over.notes%TYPE,
        o_flg_status           OUT professional_take_over.flg_status%TYPE,
        o_status_desc          OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count NUMBER := 0;
    
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM professional_take_over pto
         WHERE pto.id_professional_from = i_id_professional_from
           AND pto.flg_status = g_ext_prof_to_sch;
    
        IF l_count = 0
        THEN
        
            g_error := 'SET EXT_PROF TAKE OVER - PROFESSIONAL TAKE OVER FROM ID: ' || i_id_professional_from ||
                       '  TO PROFESSIONAL ID: ' || i_id_professional_to;
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.SET_EXT_PROF_TO ' || g_error);
            INSERT INTO professional_take_over
                (id_professional_from, id_professional_to, take_over_time, flg_status)
            VALUES
                (i_id_professional_from,
                 i_id_professional_to,
                 pk_date_utils.get_string_tstz(i_lang, i_prof, i_take_over_time, NULL),
                 g_ext_prof_to_sch);
        
        ELSE
        
            g_error := 'SET EXT_PROF TAKE OVER - PROFESSIONAL TAKE OVER FROM ID: ' || i_id_professional_from ||
                       '  TO PROFESSIONAL ID: ' || i_id_professional_to;
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.SET_EXT_PROF_TO ' || g_error);
            UPDATE professional_take_over pto
               SET pto.take_over_time     = pk_date_utils.get_string_tstz(i_lang, i_prof, i_take_over_time, NULL),
                   pto.notes              = i_notes,
                   pto.id_professional_to = i_id_professional_to
             WHERE pto.id_professional_from = i_id_professional_from;
        
        END IF;
    
        o_flg_status  := g_ext_prof_to_sch;
        o_status_desc := pk_message.get_message(i_lang, 'ADMINISTRATOR_T706');
    
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
                                              i_function => 'SET_EXT_PROF_TO',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_ext_prof_to;

    /********************************************************************************************
    * Cancel an External Professional take over
    *
    * @param i_lang                  Language id
    * @param i_id_professional       External professional ID
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/03
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION cancel_ext_prof_to
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional_take_over.id_professional_from%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CANCEL EXT_PROF TAKE OVER - EXT_PROF ID: ' || i_id_professional;
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.CANCEL_EXT_PROF_TO ' || g_error);
        DELETE FROM professional_take_over pto
         WHERE pto.id_professional_from = i_id_professional
           AND pto.flg_status = g_ext_prof_to_sch;
    
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
                                              i_function => 'CANCEL_EXT_PROF_TO',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END cancel_ext_prof_to;

    /********************************************************************************************
    * Get External professional sys_domain list
    *
    * @param i_lang                Prefered language ID
    * @param i_code_domain         Code to obtain Options
    * @param i_sys_domain_column   Sys_domain column to return (1 - VAL, 2 - DESC_VAL, 3 - ICON)
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     2.6.0.3
    * @since                       2010/07/02
    ********************************************************************************************/
    FUNCTION get_ext_state_list
    (
        i_lang              IN language.id_language%TYPE,
        i_code_domain       IN sys_domain.code_domain%TYPE,
        i_sys_domain_column IN NUMBER
    ) RETURN VARCHAR2 IS
    
        val      table_varchar;
        desc_val table_varchar;
        icon     table_varchar;
    
        l_values pk_types.cursor_type;
    
        l_error t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
        IF NOT (pk_backoffice.get_state_list(i_lang, i_code_domain, l_values, l_error))
        THEN
            RAISE l_exception;
        END IF;
    
        FETCH l_values BULK COLLECT
            INTO val, desc_val, icon;
    
        CLOSE l_values;
    
        IF i_sys_domain_column = 1
        THEN
            RETURN pk_utils.concat_table(val, g_string_delim);
        ELSIF i_sys_domain_column = 2
        THEN
            RETURN pk_utils.concat_table(desc_val, g_string_delim);
        
        ELSIF i_sys_domain_column = 3
        THEN
            RETURN pk_utils.concat_table(icon, g_string_delim);
        
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
                                              'PK_BACKOFFICE_EXT_PROF',
                                              'GET_EXT_PROF_TITLE_LIST',
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_EXT_PROF',
                                              'GET_EXT_PROF_TITLE_LIST',
                                              l_error);
            pk_types.open_my_cursor(l_values);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_ext_state_list;

    /********************************************************************************************
    * Returns External institutions list not associated with an external professional
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional (id, institution, software)
    * @param i_id_institution        Institution id
    * @param i_institution           Institution id already associated
    * @param o_ext_inst              External institution
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/07/06
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_inst_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_institution    IN table_number,
        o_ext_inst       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET EXT_INST CURSOR';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_INST_LIST ' || g_error);
        OPEN o_ext_inst FOR
            SELECT i.id_institution, pk_translation.get_translation(i_lang, i.code_institution) institution_name
              FROM institution i, inst_attributes ia
             WHERE i.flg_external = pk_alert_constant.get_yes
               AND i.flg_available = pk_alert_constant.get_yes
               AND i.id_institution = ia.id_institution
               AND i.id_institution NOT IN (SELECT column_value
                                              FROM TABLE(CAST(i_institution AS table_number)))
             ORDER BY institution_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_EXT_PROF',
                                              'GET_EXT_INST_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_ext_inst);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_ext_inst_list;

    /********************************************************************************************
    * Cancel an External Professionals
    *
    * @param i_lang                  Language id
    * @param i_professional          External professional ID's to cancel
    * @param i_id_institution        Institution ID
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/07/07
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION cancel_ext_professional
    (
        i_lang           IN language.id_language%TYPE,
        i_professional   IN table_number,
        i_id_institution IN prof_institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_external prof_institution.flg_external%TYPE;
    
        l_count NUMBER := 0;
    
    BEGIN
    
        FOR i IN 1 .. i_professional.count
        LOOP
        
            SELECT pi.flg_external
              INTO l_flg_external
              FROM prof_institution pi
             WHERE pi.id_professional = i_professional(i)
               AND pi.id_institution = i_id_institution;
        
            SELECT COUNT(pi.id_prof_institution)
              INTO l_count
              FROM prof_institution pi
             WHERE pi.id_professional = i_professional(i);
        
            IF l_flg_external = pk_alert_constant.get_yes
               AND l_count > 1
            THEN
            
                g_error := 'CANCEL EXT_PROF_INSTITUTION RELATION - EXT_PROF ID: ' || i_professional(i) ||
                           ', ID_INSTITUTION: ' || i_id_institution;
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.CANCEL_EXT_PROFESSIONAL ' || g_error);
                DELETE FROM professional_field_data pfd
                 WHERE pfd.id_professional = i_professional(i)
                   AND pfd.id_institution = i_id_institution;
                pk_api_ab_tables.del_from_prof_institution(' id_professional = ' || i_professional(i) || '
                   AND id_institution = ' ||
                                                           i_id_institution);
            
            ELSIF l_flg_external = pk_alert_constant.get_yes
                  AND l_count = 1
            THEN
            
                g_error := 'CANCEL EXT_PROF_INSTITUTION RELATION - EXT_PROF ID: ' || i_professional(i) ||
                           ', ID_INSTITUTION: ' || i_id_institution;
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.CANCEL_EXT_PROFESSIONAL ' || g_error);
                DELETE FROM professional_field_data pfd
                 WHERE pfd.id_professional = i_professional(i)
                   AND pfd.id_institution = i_id_institution;
            
                pk_api_ab_tables.del_from_prof_institution('id_professional = ' || i_professional(i) || '
                   AND id_institution = ' ||
                                                           i_id_institution);
            
                UPDATE professional p
                   SET p.flg_state = 'I'
                 WHERE p.id_professional = i_professional(i);
            
                g_error := 'SET PROFESSIONAL HISTORY';
                pk_backoffice.ins_professional_hist(i_id_professional => i_professional(i),
                                                    i_operation_type  => pk_backoffice.g_prof_hist_oper_u);
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
                                              i_function => 'CANCEL_EXT_PROFESSIONAL',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END cancel_ext_professional;

    /********************************************************************************************
    * Returns External Professionals Types list
    *
    * @param i_lang                  Language id
    * @param i_id_market             Market identifier
    * @param o_type_list             Professional types list
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/07/07
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_prof_type_list
    (
        i_lang      IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        o_type_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET TYPE_LISTF CURSOR';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_TYPE_LIST ' || g_error);
        OPEN o_type_list FOR
            SELECT stgpc.id_ext_prof_cat, stgpc.ext_prof_cat_desc
              FROM stg_ext_prof_cat stgpc
             WHERE stgpc.id_market = i_id_market;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_EXT_PROF_TYPE_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_type_list);
            RETURN FALSE;
    END get_ext_prof_type_list;

    /********************************************************************************************
    * Validate External Professionals data changed by the file imported to the staging area
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
    FUNCTION validate_ext_prof
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market    market.id_market%TYPE;
        l_license      professional_field_data.value%TYPE;
        l_professional professional.id_professional%TYPE;
    
        l_data_changed        prof_institution.dn_flg_status%TYPE := 'N';
        l_stg_id_professional stg_professional.id_stg_professional%TYPE;
    
        l_stg_professionals pk_types.cursor_type;
        l_exception EXCEPTION;
        l_error            t_error_out;
        l_prof_institution prof_institution.id_prof_institution%TYPE := 0;
    
        --CURSOR DOS PROFISSIONAIS EXTERNOS
        CURSOR c_ext_prof
        (
            c_id_institution IN institution.id_institution%TYPE,
            c_id_market      IN market.id_market%TYPE
        ) IS
            SELECT pi.id_professional, get_ext_prof_license_number(i_lang, p.id_professional, NULL, c_id_market)
              FROM prof_institution pi, professional p
             WHERE pi.flg_external = pk_alert_constant.get_yes
               AND pi.flg_state = g_ext_prof_active
               AND pi.dt_end_tstz IS NULL
               AND pi.id_institution = c_id_institution
               AND pi.id_professional = p.id_professional;
        CURSOR c_inst(i_id_professional professional.id_professional%TYPE) IS
            SELECT p_inst.id_prof_institution
              FROM (SELECT x.*
                      FROM prof_institution x
                     WHERE x.id_institution = i_id_institution
                       AND x.id_professional = i_id_institution
                     ORDER BY x.dt_end_tstz DESC) p_inst
             WHERE rownum = 1;
        l_inst prof_institution.id_prof_institution%TYPE := NULL;
    BEGIN
    
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        g_error := 'GET EXT_PROF LINKED TO INSTITUTION (ID: ' || i_id_institution;
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.VALIDATE_EXT_PROF ' || g_error);
        OPEN c_ext_prof(i_id_institution, l_id_market);
        LOOP
            FETCH c_ext_prof
                INTO l_professional, l_license;
            EXIT WHEN c_ext_prof%NOTFOUND;
        
            IF l_license IS NOT NULL
            THEN
            
                g_error := 'GET EXT_STG_PROF LINKED TO EXTERNAL PROFESSIONAL (ID: ' || l_professional;
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.VALIDATE_EXT_PROF ' || g_error);
                IF NOT get_ext_prof_by_license_number(i_lang,
                                                      NULL,
                                                      l_license,
                                                      l_id_market,
                                                      i_id_institution,
                                                      l_stg_professionals,
                                                      l_error)
                THEN
                    RAISE l_exception;
                ELSE
                
                    LOOP
                        FETCH l_stg_professionals
                            INTO l_stg_id_professional;
                        EXIT WHEN l_stg_professionals%NOTFOUND;
                    
                        IF l_stg_id_professional != 0
                        THEN
                        
                            l_data_changed := get_ext_prof_data_update(i_lang,
                                                                       l_professional,
                                                                       l_stg_id_professional,
                                                                       i_id_institution);
                        
                            g_error := 'UPDATE EXTERNAL PROFESSIONAL (ID: ' || l_professional || ') STATUS OF DATA';
                            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.VALIDATE_EXT_PROF ' || g_error);
                            IF l_data_changed = pk_alert_constant.get_yes
                            THEN
                                OPEN c_inst(l_professional);
                                LOOP
                                    FETCH c_inst
                                        INTO l_inst;
                                    EXIT WHEN c_inst%NOTFOUND;
                                
                                    pk_api_ab_tables.upd_ins_into_prof_institution(i_id_prof_institution => l_inst,
                                                                                   i_id_professional     => l_professional,
                                                                                   i_id_institution      => i_id_institution,
                                                                                   i_flg_external        => pk_alert_constant.get_yes,
                                                                                   i_dn_flg_status       => 'A',
                                                                                   o_id_prof_institution => l_prof_institution);
                                    l_inst := NULL;
                                END LOOP;
                                CLOSE c_inst;
                            END IF;
                        
                        END IF;
                    
                    END LOOP;
                
                    CLOSE l_stg_professionals;
                
                END IF;
            
            END IF;
        
        END LOOP;
    
        CLOSE c_ext_prof;
    
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
                                              i_function => 'VALIDATE_EXT_PROF',
                                              o_error    => o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'VALIDATE_EXT_PROF',
                                              o_error    => o_error);
            RETURN FALSE;
    END validate_ext_prof;

    /********************************************************************************************
    * Returns External Professionals by License number
    *
    * @param i_lang                  Language id
    * @param i_license               License number
    * @param i_stg_license           Staging area license number
    * @param i_id_market             Market identifier
    * @param i_id_institution        Institution id
    * @param o_ext_prof              External professionals
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/07/07
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_prof_by_license_number
    (
        i_lang           IN language.id_language%TYPE,
        i_license        IN professional_field_data.value%TYPE,
        i_stg_license    IN stg_professional_field_data.value%TYPE,
        i_id_market      IN market.id_market%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_ext_prof       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        CASE i_id_market
            WHEN g_market_pt THEN
                g_error := 'GET EXT_PROF CURSOR';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_BY_LICENSE_NUMBER ' || g_error);
                OPEN o_ext_prof FOR
                    SELECT p.id_professional
                      FROM professional p
                     WHERE p.num_order = i_license;
            
            WHEN g_market_nl THEN
                IF i_license IS NOT NULL
                   AND i_stg_license IS NULL
                THEN
                
                    g_error := 'GET EXT_PROF CURSOR';
                    pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_BY_LICENSE_NUMBER ' || g_error);
                    OPEN o_ext_prof FOR
                        SELECT pfd.id_professional
                          FROM professional_field_data pfd, field_market fm
                         WHERE pfd.value = i_license
                           AND pfd.id_field_market = fm.id_field_market
                           AND fm.id_field = 20
                           AND fm.id_market = g_market_nl
                           AND pfd.id_institution = 0;
                
                ELSIF i_stg_license IS NOT NULL
                      AND i_license IS NULL
                THEN
                
                    g_error := 'GET EXT_PROF CURSOR';
                    pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_BY_LICENSE_NUMBER ' || g_error);
                    OPEN o_ext_prof FOR
                        SELECT spfd.id_stg_professional
                          FROM stg_professional_field_data spfd
                         WHERE spfd.value = i_stg_license
                           AND spfd.id_field = 20
                           AND spfd.id_institution = i_id_institution;
                
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
                                              i_function => 'GET_EXT_PROF_BY_LICENSE_NUMBER',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_ext_prof);
            RETURN FALSE;
    END get_ext_prof_by_license_number;

    /********************************************************************************************
    * Returns External Professionals list by License number
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
    FUNCTION get_ext_prof_list_by_lic_num
    (
        i_lang           IN language.id_language%TYPE,
        i_license        IN professional_field_data.value%TYPE,
        i_stg_license    IN stg_professional_field_data.value%TYPE,
        i_id_market      IN market.id_market%TYPE,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR2 IS
    
        l_value VARCHAR2(200 CHAR);
    
        l_error t_error_out;
    
    BEGIN
    
        CASE i_id_market
            WHEN g_market_pt THEN
            
                SELECT nvl(pk_utils.query_to_string('SELECT p.id_professional
                      FROM professional p
                     WHERE p.num_order = ' || i_license,
                                                    g_string_delim),
                           NULL)
                  INTO l_value
                  FROM dual;
            
            WHEN g_market_nl THEN
                IF i_license IS NOT NULL
                   AND i_stg_license IS NULL
                THEN
                
                    SELECT nvl(pk_utils.query_to_string('SELECT pfd.id_professional
                          FROM professional_field_data pfd, field_market fm
                         WHERE pfd.value = ''' || i_license || '''
                           AND pfd.id_field_market = fm.id_field_market
                           AND fm.id_field = 20
                           AND fm.id_market = g_market_nl
                           AND pfd.id_institution = 0',
                                                        g_string_delim),
                               NULL)
                      INTO l_value
                      FROM dual;
                
                ELSIF i_stg_license IS NOT NULL
                      AND i_license IS NULL
                THEN
                
                    SELECT nvl(pk_utils.query_to_string('SELECT spfd.id_stg_professional
                          FROM stg_professional_field_data spfd
                         WHERE spfd.value = ''' || i_stg_license || '''
                           AND spfd.id_field = 20
                           and spfd.id_institution = ' ||
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
                                              i_function => 'GET_EXT_PROF_LITS_BY_LICENSE_NUMBER',
                                              o_error    => l_error);
            RETURN NULL;
    END get_ext_prof_list_by_lic_num;

    /********************************************************************************************
    * Compare an External Professional data with the staging area data
    *
    * @param i_lang                  Language id
    * @param i_id_professional       External professional ID
    * @param i_id_stg_professional   External professional ID in staging area
    * @param i_id_institution        Institution ID
    *
    * @return                        Flag of changed data ('Y' - different data, 'N' - no different data)
    *
    * @author                        Tércio Soares
    * @since                         2010/07/07
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_prof_data_update
    (
        i_lang                IN language.id_language%TYPE,
        i_id_professional     IN professional.id_professional%TYPE,
        i_id_stg_professional IN stg_professional.id_stg_professional%TYPE,
        i_id_institution      IN institution.id_institution%TYPE
    ) RETURN VARCHAR2 IS
    
        l_id_market    market.id_market%TYPE;
        l_data_changed prof_institution.dn_flg_status%TYPE := 'N';
    
        l_error t_error_out;
    
        --EXTERNAL PROFESSIONAL
        l_ext_prof_data VARCHAR2(4000 CHAR);
        l_title         professional.title%TYPE;
        l_first_name    professional.first_name%TYPE;
        l_middle_name   professional.middle_name%TYPE;
        l_last_name     professional.last_name%TYPE;
        l_initials      professional.initials%TYPE;
        l_dt_birth      professional.dt_birth%TYPE;
        l_gender        professional.gender%TYPE;
        l_street        professional.address%TYPE;
        l_zip_code      professional.zip_code%TYPE;
        l_city          professional.city%TYPE;
        l_phone         professional.num_contact%TYPE;
        l_cell_phone    professional.cell_phone%TYPE;
        l_fax           professional.fax%TYPE;
        l_email         professional.email%TYPE;
        l_num_order     professional.num_order%TYPE;
    
        --STG_EXTERNAL PROFESSIONAL
        l_stg_ext_prof_data VARCHAR2(4000 CHAR);
        l_stg_title         stg_professional.title%TYPE;
        l_stg_first_name    stg_professional.first_name%TYPE;
        l_stg_middle_name   stg_professional.middle_name%TYPE;
        l_stg_last_name     stg_professional.last_name%TYPE;
        l_stg_initials      stg_professional.initials%TYPE;
        l_stg_dt_birth      stg_professional.dt_birth%TYPE;
        l_stg_gender        stg_professional.gender%TYPE;
        l_stg_street        stg_professional.address%TYPE;
        l_stg_zip_code      stg_professional.zip_code%TYPE;
        l_stg_city          stg_professional.city%TYPE;
        l_stg_phone         stg_professional.num_contact%TYPE;
        l_stg_cell_phone    stg_professional.cell_phone%TYPE;
        l_stg_fax           stg_professional.fax%TYPE;
        l_stg_email         stg_professional.email%TYPE;
        l_stg_num_order     stg_professional.num_order%TYPE;
    
        --PROFESSIONAL_FIELDS_DATA
        l_pfd_value professional_field_data.value%TYPE;
    
        --STG_PROFESSIONAL_FIELDS_DATA
        l_stg_fields       table_number := table_number();
        l_stg_values       table_varchar := table_varchar();
        l_stg_institutions table_number := table_number();
    
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
    
        SELECT p.title,
               p.first_name,
               p.middle_name,
               p.last_name,
               p.initials,
               p.dt_birth,
               p.gender,
               p.address,
               p.zip_code,
               p.city,
               p.num_contact,
               p.cell_phone,
               p.fax,
               p.email,
               p.num_order
          INTO l_title,
               l_first_name,
               l_middle_name,
               l_last_name,
               l_initials,
               l_dt_birth,
               l_gender,
               l_street,
               l_zip_code,
               l_city,
               l_phone,
               l_cell_phone,
               l_fax,
               l_email,
               l_num_order
          FROM professional p
         WHERE p.id_professional = i_id_professional;
    
        SELECT stgp.title,
               stgp.first_name,
               stgp.middle_name,
               stgp.last_name,
               stgp.initials,
               stgp.dt_birth,
               stgp.gender,
               stgp.address,
               stgp.zip_code,
               stgp.city,
               stgp.num_contact,
               stgp.cell_phone,
               stgp.fax,
               stgp.email,
               stgp.num_order
          INTO l_stg_title,
               l_stg_first_name,
               l_stg_middle_name,
               l_stg_last_name,
               l_stg_initials,
               l_stg_dt_birth,
               l_stg_gender,
               l_stg_street,
               l_stg_zip_code,
               l_stg_city,
               l_stg_phone,
               l_stg_cell_phone,
               l_stg_fax,
               l_stg_email,
               l_stg_num_order
          FROM stg_professional stgp
         WHERE stgp.id_stg_professional = i_id_stg_professional
           AND stgp.id_institution = i_id_institution;
    
        l_ext_prof_data := l_title || '|' || l_first_name || '|' || l_middle_name || '|' || l_last_name || '|' ||
                           l_initials || '|' || l_dt_birth || '|' || l_gender || '|' || l_street || '|' || l_zip_code || '|' ||
                           l_city || '|' || l_phone || '|' || l_cell_phone || '|' || l_fax || '|' || l_email || '|' ||
                           l_num_order;
    
        l_stg_ext_prof_data := l_stg_title || '|' || l_stg_first_name || '|' || l_stg_middle_name || '|' ||
                               l_stg_last_name || '|' || l_stg_initials || '|' || l_stg_dt_birth || '|' || l_stg_gender || '|' ||
                               l_stg_street || '|' || l_stg_zip_code || '|' || l_stg_city || '|' || l_stg_phone || '|' ||
                               l_stg_cell_phone || '|' || l_stg_fax || '|' || l_stg_email || '|' || l_stg_num_order;
    
        IF l_ext_prof_data = l_stg_ext_prof_data
        THEN
        
            g_error := 'GET EXT_PROF FIELDS TO INSTITUTION (ID: ' || i_id_institution || ' ) MARKET (ID_MARKET: ' ||
                       l_id_market || ' )';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_DATA_UPDATE ' || g_error);
            SELECT fm.id_field_market, stgpd.value, 0
              BULK COLLECT
              INTO l_stg_fields, l_stg_values, l_stg_institutions
              FROM field f, field_market fm, stg_professional_field_data stgpd
             WHERE f.flg_field_prof_inst = 'P'
               AND f.flg_available = pk_alert_constant.get_available
               AND f.id_field_type IN (1, 2, 3, 4)
               AND f.id_field = fm.id_field
               AND fm.id_market = l_id_market
               AND fm.flg_available = pk_alert_constant.get_available
               AND stgpd.id_stg_professional = i_id_stg_professional
               AND stgpd.id_institution = i_id_institution
               AND stgpd.id_field = f.id_field;
        
            FOR i IN 1 .. l_stg_fields.count
            LOOP
            
                SELECT nvl((SELECT pfd.value
                             FROM professional_field_data pfd
                            WHERE pfd.id_field_market = l_stg_fields(i)
                              AND pfd.id_professional = i_id_professional
                              AND pfd.id_institution = l_stg_institutions(i)),
                           NULL)
                  INTO l_pfd_value
                  FROM dual;
            
                IF l_pfd_value != l_stg_values(i)
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
                                              i_function => 'GET_EXT_PROF_DATA_UPDATE',
                                              o_error    => l_error);
            RETURN NULL;
        
    END get_ext_prof_data_update;

    /********************************************************************************************
    * Compare an External Professional data with the staging area data
    *
    * @param i_lang                      Language id
    * @param i_id_professional           External professional ID
    * @param i_id_stg_professional       External professional ID's in staging area
    * @param i_id_institution            Institution ID
    * @param o_ext_prof_data             Cursor containing the different data
    * @param o_ext_prof_fields_data      Cursor containing the different data
    * @param o_ext_stg_prof_data         Cursor containing the different data
    * @param o_ext_stg_prof_fields_data  Cursor containing the different data
    * @param o_error                     Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/07/07
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_prof_data_review
    (
        i_lang                     IN language.id_language%TYPE,
        i_id_professional          IN professional.id_professional%TYPE,
        i_stg_professional         IN table_number,
        i_id_institution           IN institution.id_institution%TYPE,
        o_ext_prof_data            OUT pk_types.cursor_type,
        o_ext_prof_fields_data     OUT pk_types.cursor_type,
        o_ext_stg_prof_data        OUT pk_types.cursor_type,
        o_ext_stg_prof_fields_data OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market market.id_market%TYPE;
    
    BEGIN
    
        g_error := 'GET INSTITUTION COUNTRY';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_DATA_UPDATE ' || g_error);
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        g_error := 'GET EXT_PROF_DATA CURSOR';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_DATA_REVIEW ' || g_error);
        OPEN o_ext_prof_data FOR
            SELECT NULL id_field_market,
                   NULL id_field,
                   decode(r,
                          1,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T364'),
                          2,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T278'),
                          3,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T290'),
                          4,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T288'),
                          5,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T292'),
                          6,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T253'),
                          7,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T293'),
                          8,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T286'),
                          9,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T287'),
                          10,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T262'),
                          11,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T254'),
                          12,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T255'),
                          13,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T269'),
                          14,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T268'),
                          15,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_IDENT_T003'),
                          16,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_IDENT_T009')) field_name,
                   decode(r,
                          1,
                          'M',
                          2,
                          'T',
                          3,
                          'T',
                          4,
                          'T',
                          5,
                          'T',
                          6,
                          'M',
                          7,
                          'D',
                          8,
                          'T',
                          9,
                          'T',
                          10,
                          'T',
                          11,
                          'K',
                          12,
                          'K',
                          13,
                          'K',
                          14,
                          'T',
                          15,
                          'T',
                          16,
                          'M') field_fill_type,
                   decode(r,
                          1,
                          pk_backoffice.get_prof_title_desc(i_lang, p.title),
                          2,
                          p.first_name,
                          3,
                          p.middle_name,
                          4,
                          p.last_name,
                          5,
                          p.initials,
                          6,
                          p.gender,
                          7,
                          pk_backoffice.get_date_to_be_sent(i_lang, p.dt_birth),
                          8,
                          p.address,
                          9,
                          p.zip_code,
                          10,
                          p.city,
                          11,
                          p.num_contact,
                          12,
                          p.cell_phone,
                          13,
                          p.fax,
                          14,
                          p.email,
                          15,
                          p.num_order,
                          16,
                          p.id_speciality) field_value,
                   decode(r,
                          1,
                          pk_backoffice.get_prof_title_desc(i_lang, p.title),
                          2,
                          p.first_name,
                          3,
                          p.middle_name,
                          4,
                          p.last_name,
                          5,
                          p.initials,
                          6,
                          pk_sysdomain.get_domain('PROFESSIONAL.GENDER', p.gender, i_lang),
                          7,
                          pk_backoffice.get_date_to_be_sent(i_lang, p.dt_birth),
                          8,
                          p.address,
                          9,
                          p.zip_code,
                          10,
                          p.city,
                          11,
                          p.num_contact,
                          12,
                          p.cell_phone,
                          13,
                          p.fax,
                          14,
                          p.email,
                          15,
                          p.num_order,
                          16,
                          pk_translation.get_translation(i_lang, 'SPECIALITY.CODE_SPECIALITY.' || p.id_speciality)) field_value_desc,
                   decode(r,
                          1,
                          'i_title',
                          2,
                          'i_first_name',
                          3,
                          'i_middle_name',
                          4,
                          'i_last_name',
                          5,
                          'i_initials',
                          6,
                          'i_gender',
                          7,
                          'i_dt_birth',
                          8,
                          'i_street',
                          9,
                          'i_zip_code',
                          10,
                          'i_city',
                          11,
                          'i_phone',
                          12,
                          'i_cell_phone',
                          13,
                          'i_fax',
                          14,
                          'i_email',
                          15,
                          'i_num_order',
                          16,
                          'i_speciality') set_parameters
              FROM professional p,
                   (SELECT rownum r
                      FROM all_objects
                     WHERE rownum <= 16)
             WHERE p.id_professional = i_id_professional;
    
        g_error := 'GET EXT_PROF_FIELDS_DATA CURSOR';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_DATA_REVIEW ' || g_error);
        OPEN o_ext_prof_fields_data FOR
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
                   pfd.value field_value,
                   decode(fm.fill_type, 'M', NULL, pfd.value) field_value_desc,
                   pfd.id_institution,
                   NULL set_parameters
              FROM field f, field_market fm, professional_field_data pfd
             WHERE f.flg_field_prof_inst = 'P'
               AND f.flg_available = pk_alert_constant.get_available
               AND f.id_field_type IN (1, 2, 3)
               AND f.id_field = fm.id_field
               AND fm.id_market = l_id_market
               AND fm.flg_available = pk_alert_constant.get_available
               AND pfd.id_professional(+) = i_id_professional
               AND pfd.id_field_market(+) = fm.id_field_market;
    
        g_error := 'GET EXT_STG_PROF_DATA CURSOR';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_DATA_REVIEW ' || g_error);
        OPEN o_ext_stg_prof_data FOR
            SELECT NULL id_field_market,
                   NULL id_field,
                   decode(r,
                          1,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T364'),
                          2,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T278'),
                          3,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T290'),
                          4,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T288'),
                          5,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T292'),
                          6,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T253'),
                          7,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T293'),
                          8,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T286'),
                          9,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T287'),
                          10,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T262'),
                          11,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T254'),
                          12,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T255'),
                          13,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T269'),
                          14,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T268'),
                          15,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_IDENT_T003')) field_name,
                   decode(r,
                          1,
                          'M',
                          2,
                          'T',
                          3,
                          'T',
                          4,
                          'T',
                          5,
                          'T',
                          6,
                          'M',
                          7,
                          'D',
                          8,
                          'T',
                          9,
                          'T',
                          10,
                          'T',
                          11,
                          'K',
                          12,
                          'K',
                          13,
                          'K',
                          14,
                          'T',
                          15,
                          'T') field_fill_type,
                   decode(r,
                          1,
                          pk_backoffice.get_prof_title_desc(i_lang, stgp.title),
                          2,
                          stgp.first_name,
                          3,
                          stgp.middle_name,
                          4,
                          stgp.last_name,
                          5,
                          stgp.initials,
                          6,
                          stgp.gender,
                          7,
                          pk_backoffice.get_date_to_be_sent(i_lang, stgp.dt_birth),
                          8,
                          stgp.address,
                          9,
                          stgp.zip_code,
                          10,
                          stgp.city,
                          11,
                          stgp.num_contact,
                          12,
                          stgp.cell_phone,
                          13,
                          stgp.fax,
                          14,
                          stgp.email,
                          15,
                          stgp.num_order) field_value,
                   decode(r,
                          1,
                          pk_backoffice.get_prof_title_desc(i_lang, stgp.title),
                          2,
                          stgp.first_name,
                          3,
                          stgp.middle_name,
                          4,
                          stgp.last_name,
                          5,
                          stgp.initials,
                          6,
                          pk_sysdomain.get_domain('PROFESSIONAL.GENDER', stgp.gender, i_lang),
                          7,
                          pk_backoffice.get_date_to_be_sent(i_lang, stgp.dt_birth),
                          8,
                          stgp.address,
                          9,
                          stgp.zip_code,
                          10,
                          stgp.city,
                          11,
                          stgp.num_contact,
                          12,
                          stgp.cell_phone,
                          13,
                          stgp.fax,
                          14,
                          stgp.email,
                          15,
                          stgp.num_order) field_value_desc,
                   decode(r,
                          1,
                          'i_title',
                          2,
                          'i_first_name',
                          3,
                          'i_middle_name',
                          4,
                          'i_last_name',
                          5,
                          'i_initials',
                          6,
                          'i_gender',
                          7,
                          'i_dt_birth',
                          8,
                          'i_street',
                          9,
                          'i_zip_code',
                          10,
                          'i_city',
                          11,
                          'i_phone',
                          12,
                          'i_cell_phone',
                          13,
                          'i_fax',
                          14,
                          'i_email',
                          15,
                          'i_num_order') set_parameters
              FROM stg_professional stgp,
                   (SELECT rownum r
                      FROM all_objects
                     WHERE rownum <= 15)
             WHERE stgp.id_stg_professional IN
                   (SELECT column_value
                      FROM TABLE(CAST(i_stg_professional AS table_number)))
               AND stgp.id_institution = i_id_institution;
    
        g_error := 'GET EXT_STG_PROF_FIELDS_DATA CURSOR';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_DATA_REVIEW ' || g_error);
        OPEN o_ext_stg_prof_fields_data FOR
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
                   stgpd.value field_value,
                   decode(fm.fill_type, 'M', NULL, stgpd.value) field_value_desc,
                   0 id_institution,
                   NULL set_parameters
              FROM field f, field_market fm, stg_professional_field_data stgpd
             WHERE f.flg_field_prof_inst = 'P'
               AND f.flg_available = pk_alert_constant.get_available
               AND f.id_field_type IN (1, 2, 3)
               AND f.id_field = fm.id_field
               AND fm.id_market = l_id_market
               AND fm.flg_available = pk_alert_constant.get_available
               AND stgpd.id_stg_professional IN
                   (SELECT column_value
                      FROM TABLE(CAST(i_stg_professional AS table_number)))
               AND stgpd.id_field(+) = f.id_field
               AND stgpd.id_institution(+) = i_id_institution;
    
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
            pk_types.open_my_cursor(o_ext_prof_data);
            pk_types.open_my_cursor(o_ext_stg_prof_data);
            RETURN FALSE;
        
    END get_ext_prof_data_review;

    /********************************************************************************************
    * Import the staging area data for an External Professional
    *
    * @param i_lang                  Language id
    * @param i_professional          External professional ID's
    * @param i_stg_professional      External professional ID in staging area
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
        i_lang             IN language.id_language%TYPE,
        i_professional     IN table_number,
        i_stg_professional IN table_number,
        i_id_institution   IN institution.id_institution%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_country country.id_country%TYPE;
        l_id_market  market.id_market%TYPE;
        l_exception EXCEPTION;
        l_error t_error_out;
    
        --EXTERNAL PROFESSIONAL
        l_id_professional  professional.id_professional%TYPE;
        l_title            professional.title%TYPE;
        l_first_name       professional.first_name%TYPE;
        l_middle_name      professional.middle_name%TYPE;
        l_last_name        professional.last_name%TYPE;
        l_initials         professional.initials%TYPE;
        l_dt_birth         professional.dt_birth%TYPE;
        l_gender           professional.gender%TYPE;
        l_street           professional.address%TYPE;
        l_zip_code         professional.zip_code%TYPE;
        l_city             professional.city%TYPE;
        l_phone            professional.num_contact%TYPE;
        l_cell_phone       professional.cell_phone%TYPE;
        l_fax              professional.fax%TYPE;
        l_email            professional.email%TYPE;
        l_num_order        professional.num_order%TYPE;
        l_prof_institution prof_institution.id_prof_institution%TYPE := 0;
    
        --PROFESSIONAL_FIELDS_DATA
        l_fields       table_number := table_number();
        l_values       table_varchar := table_varchar();
        l_institutions table_number := table_number();
        l_prof_pref_pk prof_institution.id_prof_institution%TYPE := NULL;
    
        CURSOR c_ext_prof(c_id_stg_professional stg_professional.id_stg_professional%TYPE) IS
            SELECT stgp.title,
                   stgp.first_name,
                   stgp.middle_name,
                   stgp.last_name,
                   stgp.initials,
                   stgp.dt_birth,
                   stgp.gender,
                   stgp.address,
                   stgp.zip_code,
                   stgp.city,
                   stgp.num_contact,
                   stgp.cell_phone,
                   stgp.fax,
                   stgp.email,
                   stgp.num_order
              FROM stg_professional stgp
             WHERE stgp.id_stg_professional = c_id_stg_professional
               AND stgp.id_institution = i_id_institution;
    
    BEGIN
    
        g_error := 'GET INSTITUTION COUNTRY';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.SET_ACCEPT_DATA_UPDATE ' || g_error);
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        SELECT nvl((SELECT ia.id_country
                     FROM inst_attributes ia
                    WHERE ia.id_institution = i_id_institution),
                   -1)
          INTO l_id_country
          FROM dual;
    
        FOR i IN 1 .. i_professional.count
        LOOP
        
            g_error := 'GET EXT_PROF FIELDS TO INSTITUTION (ID: ' || i_id_institution || ' ) MARKET (ID_MARKET: ' ||
                       l_id_market || ' )';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.SET_ACCEPT_DATA_UPDATE ' || g_error);
            SELECT fm.id_field_market, stgpd.value, 0
              BULK COLLECT
              INTO l_fields, l_values, l_institutions
              FROM field f, field_market fm, stg_professional_field_data stgpd
             WHERE f.flg_field_prof_inst = 'P'
               AND f.flg_available = pk_alert_constant.get_available
               AND f.id_field_type IN (1, 2, 3, 4)
               AND f.id_field = fm.id_field
               AND fm.id_market = l_id_market
               AND fm.flg_available = pk_alert_constant.get_available
               AND stgpd.id_stg_professional = i_stg_professional(i)
               AND stgpd.id_institution = i_id_institution
               AND stgpd.id_field = f.id_field;
        
            OPEN c_ext_prof(i_stg_professional(i));
            LOOP
            
                g_error := 'GET EXT_PROF DATA (ID_STG_PROFESSIONAL: ' || i_id_institution || ' ) MARKET (ID_MARKET: ' ||
                           l_id_market || ' )';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.SET_ACCEPT_DATA_UPDATE ' || g_error);
                FETCH c_ext_prof
                    INTO l_title,
                         l_first_name,
                         l_middle_name,
                         l_last_name,
                         l_initials,
                         l_dt_birth,
                         l_gender,
                         l_street,
                         l_zip_code,
                         l_city,
                         l_phone,
                         l_cell_phone,
                         l_fax,
                         l_email,
                         l_num_order;
                EXIT WHEN c_ext_prof%NOTFOUND;
            
                IF NOT set_ext_professional(i_lang            => i_lang,
                                            i_id_professional => i_professional(i),
                                            i_title           => l_title,
                                            i_first_name      => l_first_name,
                                            i_middle_name     => l_middle_name,
                                            i_last_name       => l_last_name,
                                            i_initials        => l_initials,
                                            i_dt_birth        => pk_backoffice.get_date_to_be_sent(i_lang, l_dt_birth),
                                            i_gender          => l_gender,
                                            i_street          => l_street,
                                            i_zip_code        => l_zip_code,
                                            i_city            => l_city,
                                            i_id_country      => l_id_country,
                                            i_phone           => l_phone,
                                            i_cell_phone      => l_cell_phone,
                                            i_fax             => l_fax,
                                            i_email           => l_email,
                                            i_num_order       => l_num_order,
                                            i_speciality      => NULL,
                                            i_id_institution  => i_id_institution,
                                            i_fields          => l_fields,
                                            i_institution     => l_institutions,
                                            i_values          => l_values,
                                            o_professional    => l_id_professional,
                                            o_error           => l_error)
                THEN
                    RAISE l_exception;
                
                ELSE
                    BEGIN
                        SELECT pi.id_prof_institution
                          INTO l_prof_institution
                          FROM prof_institution pi
                         WHERE pi.id_professional = i_professional(i)
                           AND pi.id_institution = i_id_institution
                           AND pi.flg_external = pk_alert_constant.get_yes;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_prof_institution := NULL;
                    END;
                    pk_api_ab_tables.upd_ins_into_prof_institution(i_id_prof_institution => l_prof_institution,
                                                                   i_id_professional     => i_professional(i),
                                                                   i_id_institution      => i_id_institution,
                                                                   i_flg_external        => pk_alert_constant.get_yes,
                                                                   i_dn_flg_status       => 'V',
                                                                   o_id_prof_institution => l_prof_institution);
                
                END IF;
            
            END LOOP;
        
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
    * Reject the staging area data for an External Professional
    *
    * @param i_lang                  Language id
    * @param i_professional          External professional ID's
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
        i_professional   IN table_number,
        i_id_institution IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof_institution prof_institution.id_prof_institution%TYPE := 0;
        l_pi_id            prof_institution.id_prof_institution%TYPE := NULL;
    BEGIN
    
        FOR i IN 1 .. i_professional.count
        LOOP
        
            g_error := 'UPDATE PROF_INSTITUTION to DN_FLG_STATUS = ''E'' - ID_PROFESSIONAL = ' || i_professional(i) ||
                       ' IN ID_INSTITUTION = ' || i_id_institution;
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.SET_REJECT_DATA_UPDATE ' || g_error);
            BEGIN
                SELECT pi.id_prof_institution
                  INTO l_prof_institution
                  FROM prof_institution pi
                 WHERE pi.id_professional = i_professional(i)
                   AND pi.id_institution = i_id_institution
                   AND pi.flg_external = pk_alert_constant.get_yes;
            EXCEPTION
                WHEN no_data_found THEN
                    l_prof_institution := NULL;
            END;
            pk_api_ab_tables.upd_ins_into_prof_institution(i_id_prof_institution => l_prof_institution,
                                                           i_id_professional     => i_professional(i),
                                                           i_id_institution      => i_id_institution,
                                                           i_flg_external        => pk_alert_constant.get_yes,
                                                           i_dn_flg_status       => 'E',
                                                           o_id_prof_institution => l_prof_institution);
        
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
    FUNCTION set_delete_stg_ext_prof_data
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_professional  prof_institution.id_professional%TYPE;
        l_id_market        market.id_market%TYPE;
        l_prof_institution prof_institution.id_prof_institution%TYPE := 0;
        l_institution      institution.id_institution%TYPE := 0;
    
        --CURSOR DOS PROFISSIONAIS EXTERNOS
        CURSOR c_ext_prof(c_id_institution IN institution.id_institution%TYPE) IS
            SELECT pi.id_professional
              FROM prof_institution pi, professional p
             WHERE pi.flg_external = pk_alert_constant.get_yes
               AND pi.flg_state = g_ext_prof_active
               AND pi.dt_end_tstz IS NULL
               AND pi.id_institution = c_id_institution
               AND pi.id_professional = p.id_professional;
    
    BEGIN
    
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        g_error := 'DELETE ALL DATA FROM EXTERNAL PROFESSIONALS IN STG_AREA FROM ID_INSTITUTION = ' || i_id_institution;
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.SET_DELETE_STG_EXT_PROF_DATA: ' || g_error);
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
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.SET_DELETE_STG_EXT_PROF_DATA ' || g_error);
        OPEN c_ext_prof(i_id_institution);
        LOOP
            FETCH c_ext_prof
                INTO l_id_professional;
            EXIT WHEN c_ext_prof%NOTFOUND;
        
            g_error := 'UPDATE FLAG DATA FROM EXTERNAL PROFESSIONALS IN  ID_INSTITUTION = ' || i_id_institution;
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.SET_DELETE_STG_EXT_PROF_DATA: ' || g_error);
            BEGIN
                SELECT pi.id_prof_institution
                  INTO l_prof_institution
                  FROM prof_institution pi
                 WHERE pi.id_professional = l_id_professional
                   AND pi.id_institution = i_id_institution
                   AND pi.flg_external = pk_alert_constant.get_yes;
            EXCEPTION
                WHEN no_data_found THEN
                    l_prof_institution := NULL;
            END;
            pk_api_ab_tables.upd_ins_into_prof_institution(i_id_prof_institution => NULL,
                                                           i_id_professional     => l_id_professional,
                                                           i_id_institution      => i_id_institution,
                                                           i_flg_external        => pk_alert_constant.get_yes,
                                                           i_dn_flg_status       => 'V',
                                                           o_id_prof_institution => l_prof_institution);
        
        END LOOP;
    
        CLOSE c_ext_prof;
    
        g_error := 'UPDATE FLAG DATA FROM EXTERNAL INSTITUTION IN  ID_MARKET = ' || l_id_market;
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.SET_DELETE_STG_EXT_PROF_DATA: ' || g_error);
        FOR inst IN (SELECT i.id_institution
                       FROM institution i
                      WHERE i.id_market = l_id_market
                        AND i.flg_external = pk_alert_constant.get_yes)
        LOOP
            pk_api_ab_tables.upd_ins_into_ab_institution(i_id_ab_institution          => inst.id_institution,
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
                                                         i_flg_external               => NULL,
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
        
    END set_delete_stg_ext_prof_data;
    /********************************************************************************************
    * Get External professional speciality list
    *
    * @param i_lang                Prefered language ID
    * @param i_column              speciality column to return (1 - id, 2 - DESC)
    *
    *
    * @return                      specialities list (id or description)
    *
    * @author                      RMGM
    * @version                     2.6.1
    * @since                       2011/04/07
    ********************************************************************************************/

    FUNCTION get_ext_prof_spec
    (
        i_lang   IN language.id_language%TYPE,
        i_column IN NUMBER
    ) RETURN VARCHAR2 IS
        c_specs     pk_types.cursor_type;
        a_spec_id   table_number := table_number();
        a_spec_desc table_varchar := table_varchar();
        a_ranks     table_number := table_number();
        l_error     t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
        g_error := 'get speciality list';
        IF NOT pk_list.get_spec_list(i_lang, c_specs, l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'fetch speciality list';
        FETCH c_specs BULK COLLECT
            INTO a_spec_id, a_ranks, a_spec_desc;
    
        g_error := 'close speciality cursor';
        CLOSE c_specs;
    
        g_error := 'return speciality list into table';
        IF i_column = 1
        THEN
            RETURN pk_utils.concat_table(a_spec_id, g_string_delim);
        ELSIF i_column = 2
        THEN
            RETURN pk_utils.concat_table(a_spec_desc, g_string_delim);
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
                                              'PK_BACKOFFICE_EXT_PROF',
                                              'GET_EXT_PROF_SPEC',
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_EXT_PROF',
                                              'GET_EXT_PROF_SPEC',
                                              l_error);
            pk_types.open_my_cursor(c_specs);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_ext_prof_spec;

    /********************************************************************************************
    * Get External professional multichoice values and descriptions
    *
    * @param i_lang                Prefered language ID
    * @param i_id_professional     Professional id
    * @param i_area                Professional configuration area
    * @param i_argument            Professional configuration argument
    * @param i_column              column to return (1 - ID's list, 2 - DESCRIPTIONS list, 3 - ID, 4 - DESCRIPTION)
    *
    *
    * @return                      multichoice (id/description)
    *
    * @author                      JTS
    * @version                     2.6.1.13
    * @since                       2012/12/11
    ********************************************************************************************/
    FUNCTION get_ext_prof_mc_values
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_area            IN NUMBER,
        i_argument        IN NUMBER,
        i_column          IN NUMBER
    ) RETURN VARCHAR2 IS
    
        c_country        pk_types.cursor_type;
        a_mc_id          table_number := table_number();
        a_mc_rank        table_number := table_number();
        a_mc_desc        table_varchar := table_varchar();
        a_mc_flg_default table_varchar := table_varchar();
    
        l_return VARCHAR2(1000 CHAR);
        l_error  t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
    
        CASE (i_area)
        --PROFESSIONALS PERSONAL DATA
            WHEN 1 THEN
                CASE (i_argument)
                    WHEN 1 THEN
                    
                        g_error := 'return titles list into table';
                        IF i_column = 1
                        THEN
                            RETURN get_ext_state_list(i_lang, 'PROFESSIONAL.TITLE', 1);
                        ELSIF i_column = 2
                        THEN
                            RETURN get_ext_state_list(i_lang, 'PROFESSIONAL.TITLE', 2);
                        
                            g_error := 'return professional title';
                        ELSIF i_column = 3
                        THEN
                            SELECT p.title
                              INTO l_return
                              FROM professional p
                             WHERE p.id_professional = i_id_professional;
                        
                            RETURN l_return;
                        
                        ELSIF i_column = 4
                        THEN
                        
                            SELECT p.title
                              INTO l_return
                              FROM professional p
                             WHERE p.id_professional = i_id_professional;
                        
                            RETURN pk_backoffice.get_prof_title_desc(i_lang, l_return);
                        ELSE
                            RETURN NULL;
                        END IF;
                    
                    WHEN 6 THEN
                    
                        g_error := 'return gender list into table';
                        IF i_column = 1
                        THEN
                            RETURN get_ext_state_list(i_lang, 'PROFESSIONAL.GENDER', 1);
                        ELSIF i_column = 2
                        THEN
                            RETURN get_ext_state_list(i_lang, 'PROFESSIONAL.GENDER', 2);
                        
                            g_error := 'return professional gender';
                        ELSIF i_column = 3
                        THEN
                            SELECT p.gender
                              INTO l_return
                              FROM professional p
                             WHERE p.id_professional = i_id_professional;
                        
                            RETURN l_return;
                        
                        ELSIF i_column = 4
                        THEN
                        
                            SELECT p.gender
                              INTO l_return
                              FROM professional p
                             WHERE p.id_professional = i_id_professional;
                        
                            RETURN pk_sysdomain.get_domain('PROFESSIONAL.GENDER', l_return, i_lang);
                        ELSE
                            RETURN NULL;
                        END IF;
                    
                    ELSE
                        RETURN NULL;
                END CASE;
                --PROFESSIONALS PERSONAL CONTACTS
            WHEN 2 THEN
                CASE (i_argument)
                    WHEN 8 THEN
                        IF NOT pk_list.get_country_list(i_lang, profissional(0, 0, 0), c_country, l_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                        g_error := 'fetch country list';
                        FETCH c_country BULK COLLECT
                            INTO a_mc_id, a_mc_rank, a_mc_desc, a_mc_flg_default;
                    
                        g_error := 'close countries cursor';
                        CLOSE c_country;
                    
                        g_error := 'return countries list into table';
                        IF i_column = 1
                        THEN
                            RETURN pk_utils.concat_table(a_mc_id, g_string_delim);
                        ELSIF i_column = 2
                        THEN
                            RETURN pk_utils.concat_table(a_mc_desc, g_string_delim);
                        
                            g_error := 'return professional country';
                        ELSIF i_column = 3
                        THEN
                            SELECT to_char(p.id_country)
                              INTO l_return
                              FROM professional p
                             WHERE p.id_professional = i_id_professional;
                        
                            RETURN l_return;
                        ELSIF i_column = 4
                        THEN
                        
                            SELECT pk_translation.get_translation(i_lang,
                                                                  (SELECT c.code_country
                                                                     FROM country c
                                                                    WHERE c.id_country =
                                                                          (SELECT p.id_country
                                                                             FROM professional p
                                                                            WHERE p.id_professional = i_id_professional)))
                              INTO l_return
                              FROM dual;
                        
                            RETURN l_return;
                        ELSE
                            RETURN NULL;
                        END IF;
                    ELSE
                        RETURN NULL;
                END CASE;
                --PROFESSIONALS PROFESSIONAL DATA
            WHEN 3 THEN
                CASE (i_argument)
                    WHEN 2 THEN
                    
                        g_error := 'return specialties list into table';
                        IF i_column = 1
                        THEN
                            RETURN get_ext_prof_spec(i_lang, 1);
                        ELSIF i_column = 2
                        THEN
                            RETURN get_ext_prof_spec(i_lang, 2);
                        
                            g_error := 'return professional specialty';
                        ELSIF i_column = 3
                        THEN
                            SELECT to_char(p.id_speciality)
                              INTO l_return
                              FROM professional p
                             WHERE p.id_professional = i_id_professional;
                        
                            RETURN l_return;
                        ELSIF i_column = 4
                        THEN
                        
                            SELECT pk_translation.get_translation(i_lang,
                                                                  (SELECT s.code_speciality
                                                                     FROM speciality s
                                                                    WHERE s.id_speciality =
                                                                          (SELECT p.id_speciality
                                                                             FROM professional p
                                                                            WHERE p.id_professional = i_id_professional)))
                              INTO l_return
                              FROM dual;
                        
                            RETURN l_return;
                        ELSE
                            RETURN NULL;
                        END IF;
                    ELSE
                        RETURN NULL;
                END CASE;
            ELSE
                RETURN NULL;
        END CASE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error.err_desc,
                                              'ALERT',
                                              'PK_BACKOFFICE_EXT_PROF',
                                              'GET_EXT_PROF_MC_VALUES',
                                              l_error);
            pk_types.open_my_cursor(c_country);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_EXT_PROF',
                                              'GET_EXT_PROF_MC_VALUES',
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_ext_prof_mc_values;

BEGIN
    pk_alertlog.log_init(pk_alertlog.who_am_i);

END pk_backoffice_ext_prof;
/
