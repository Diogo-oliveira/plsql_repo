/*-- Last Change Revision: $Rev: 1870590 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-09-28 16:29:05 +0100 (sex, 28 set 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_protocol_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_protocol_prm';

    -- global vars
    g_error            t_big_char;
    g_flg_available    t_flg_char;
    g_active           t_flg_char;
    g_version          t_low_char;
    g_func_name        t_med_char;
    g_finished         t_flg_char;
    g_temporary        t_flg_char;
    g_element_question t_flg_char;
    g_element_protocol t_flg_char;

    g_array_size  NUMBER;
    g_array_size1 NUMBER;

    g_cfg_done t_low_char;
    -- Private Methods

    -- content loader method

    -- searcheable loader method
    FUNCTION set_protocol_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_protocol_search');
        INSERT INTO protocol
            (id_protocol,
             id_protocol_previous_version,
             protocol_desc,
             dt_protocol,
             flg_status,
             id_ebm,
             context_title,
             context_adaptation,
             context_type_media,
             context_editor,
             context_edition_site,
             context_edition,
             dt_context_edition,
             context_access,
             id_context_language,
             flg_context_image,
             context_subtitle,
             id_context_associated_language,
             id_professional,
             id_institution,
             id_software,
             id_prof_cancel,
             dt_cancel,
             flg_type_recommendation,
             adw_last_update,
             context_desc,
             id_content)
            SELECT seq_protocol.nextval,
                   def_data.id_protocol_previous_version,
                   def_data.protocol_desc,
                   def_data.dt_protocol,
                   def_data.flg_status,
                   def_data.id_ebm,
                   def_data.context_title,
                   def_data.context_adaptation,
                   def_data.context_type_media,
                   def_data.context_editor,
                   def_data.context_edition_site,
                   def_data.context_edition,
                   def_data.dt_context_edition,
                   def_data.context_access,
                   def_data.id_context_language,
                   def_data.flg_context_image,
                   def_data.context_subtitle,
                   def_data.id_context_associated_language,
                   def_data.id_professional,
                   def_data.id_institution,
                   def_data.id_software,
                   def_data.id_prof_cancel,
                   def_data.dt_cancel,
                   def_data.flg_type_recommendation,
                   SYSDATE,
                   def_data.context_desc,
                   def_data.id_content
              FROM (SELECT temp_data.id_protocol_previous_version,
                           temp_data.protocol_desc,
                           temp_data.dt_protocol,
                           temp_data.flg_status,
                           temp_data.id_ebm,
                           temp_data.context_title,
                           temp_data.context_adaptation,
                           temp_data.context_type_media,
                           temp_data.context_editor,
                           temp_data.context_edition_site,
                           temp_data.context_edition,
                           temp_data.dt_context_edition,
                           temp_data.context_access,
                           temp_data.id_context_language,
                           temp_data.flg_context_image,
                           temp_data.context_subtitle,
                           temp_data.id_context_associated_language,
                           temp_data.id_professional,
                           temp_data.id_institution,
                           temp_data.id_software,
                           temp_data.id_prof_cancel,
                           temp_data.dt_cancel,
                           temp_data.flg_type_recommendation,
                           temp_data.adw_last_update,
                           temp_data.context_desc,
                           temp_data.id_content,
                           row_number() over(PARTITION BY temp_data.id_content
                           
                           ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT src_tbl.id_content,
                                   src_tbl.flg_status,
                                   src_tbl.id_protocol_previous_version,
                                   src_tbl.protocol_desc,
                                   NULL                                   dt_protocol,
                                   src_tbl.id_ebm,
                                   src_tbl.context_title,
                                   src_tbl.context_adaptation,
                                   src_tbl.context_type_media,
                                   src_tbl.context_editor,
                                   src_tbl.context_edition_site,
                                   src_tbl.context_edition,
                                   src_tbl.dt_context_edition,
                                   src_tbl.context_access,
                                   src_tbl.id_context_language,
                                   src_tbl.flg_context_image,
                                   src_tbl.context_subtitle,
                                   src_tbl.id_context_associated_language,
                                   NULL                                   id_professional,
                                   i_institution                          id_institution,
                                   src_tbl.id_software,
                                   NULL                                   id_prof_cancel,
                                   NULL                                   dt_cancel,
                                   src_tbl.flg_type_recommendation,
                                   NULL                                   adw_last_update,
                                   src_tbl.context_desc,
                                   pmv.id_market,
                                   pmv.version
                            -- decode FKS to dest_vals
                              FROM alert_default.protocol src_tbl
                             INNER JOIN alert_default.protocol_mrk_vrs pmv
                                ON (pmv.id_protocol = src_tbl.id_protocol)
                             WHERE pmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND pmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND EXISTS (SELECT 0
                                      FROM alert_default.protocol_element pe
                                     INNER JOIN alert_default.protocol_task pt
                                        ON (pt.id_group_task = pe.id_protocol_element)
                                     WHERE pe.id_protocol = src_tbl.id_protocol
                                       AND pe.element_type = g_temporary)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM protocol dest_tbl
                     WHERE id_content = def_data.id_content
                       AND def_data.id_institution = def_data.id_institution
                       AND def_data.flg_status = g_finished);
        o_result_tbl := SQL%ROWCOUNT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_protocol_search;
    FUNCTION set_protocol_link_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_protocol_link_search');
        INSERT INTO protocol_link
            (id_protocol_link, id_protocol, id_link, link_type)
            SELECT seq_protocol_link.nextval, id_protocol, id_link, link_type
              FROM (SELECT temp_data.id_protocol, temp_data.link_type, temp_data.id_link
                      FROM (SELECT nvl((SELECT ext_p.id_protocol
                                         FROM protocol ext_p
                                        INNER JOIN alert_default.protocol int_p
                                           ON (int_p.id_content = ext_p.id_content)
                                        WHERE ext_p.flg_status = g_finished
                                          AND int_p.id_protocol = src_tbl.id_protocol),
                                       0) id_protocol,
                                   src_tbl.link_type,
                                   ext_sd.id_dept id_link
                              FROM alert_default.protocol_link src_tbl
                             INNER JOIN alert_default.protocol_mrk_vrs pmv
                                ON (pmv.id_protocol = src_tbl.id_protocol)
                             INNER JOIN software_dept ext_sd
                                ON (ext_sd.id_software = src_tbl.id_link)
                             WHERE pmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND pmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                  -- Environment (department id)
                               AND src_tbl.link_type = 'E'
                               AND EXISTS (SELECT 0
                                      FROM dept ext_d
                                     WHERE ext_d.id_dept = ext_sd.id_dept
                                       AND ext_d.flg_available = g_flg_available
                                       AND ext_d.id_institution = i_institution)) temp_data
                     WHERE temp_data.id_protocol > 0
                    UNION
                    
                    SELECT temp_data.id_protocol, temp_data.link_type, temp_data.id_link
                      FROM (SELECT nvl((SELECT ext_p.id_protocol
                                         FROM protocol ext_p
                                        INNER JOIN alert_default.protocol int_p
                                           ON (int_p.id_content = ext_p.id_content)
                                        WHERE ext_p.flg_status = g_finished
                                          AND int_p.id_protocol = src_tbl.id_protocol),
                                       0) id_protocol,
                                   src_tbl.link_type,
                                   id_link
                              FROM alert_default.protocol_link src_tbl
                             INNER JOIN alert_default.protocol_mrk_vrs pmv
                                ON (pmv.id_protocol = src_tbl.id_protocol)
                             WHERE pmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND pmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                  -- complaint
                               AND src_tbl.link_type = 'C'
                               AND EXISTS (SELECT 0
                                      FROM complaint ext_tbl
                                     WHERE ext_tbl.id_complaint = src_tbl.id_link
                                       AND ext_tbl.flg_available = g_flg_available)) temp_data
                     WHERE temp_data.id_protocol > 0
                    UNION
                    
                    SELECT temp_data.id_protocol, temp_data.link_type, temp_data.id_link
                      FROM (SELECT nvl((SELECT ext_p.id_protocol
                                         FROM protocol ext_p
                                        INNER JOIN alert_default.protocol int_p
                                           ON (int_p.id_content = ext_p.id_content)
                                        WHERE ext_p.flg_status = g_finished
                                          AND int_p.id_protocol = src_tbl.id_protocol),
                                       0) id_protocol,
                                   src_tbl.link_type,
                                   src_tbl.id_link
                              FROM alert_default.protocol_link src_tbl
                             INNER JOIN alert_default.protocol_mrk_vrs pmv
                                ON (pmv.id_protocol = src_tbl.id_protocol)
                             WHERE pmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND pmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                  -- professional category
                               AND src_tbl.link_type = 'P'
                               AND EXISTS (SELECT 0
                                      FROM category ext_tbl
                                     WHERE ext_tbl.id_category = src_tbl.id_link
                                       AND ext_tbl.flg_available = g_flg_available)) temp_data
                     WHERE temp_data.id_protocol > 0
                    UNION
                    
                    SELECT temp_data.id_protocol, temp_data.link_type, temp_data.id_link
                      FROM (SELECT nvl((SELECT ext_p.id_protocol
                                         FROM protocol ext_p
                                        INNER JOIN alert_default.protocol int_p
                                           ON (int_p.id_content = ext_p.id_content)
                                        WHERE ext_p.flg_status = g_finished
                                          AND int_p.id_protocol = src_tbl.id_protocol),
                                       0) id_protocol,
                                   src_tbl.link_type,
                                   decode(i_software(1),
                                          3,
                                          nvl((SELECT ext_cs.id_clinical_service
                                                FROM clinical_service ext_cs
                                               INNER JOIN alert_default.clinical_service int_cs
                                                  ON (int_cs.id_content = ext_cs.id_content AND
                                                     int_cs.flg_available = g_flg_available)
                                               WHERE ext_cs.flg_available = g_flg_available
                                                 AND int_cs.id_clinical_service = src_tbl.id_link),
                                              0),
                                          nvl((SELECT ext_s.id_speciality
                                                FROM speciality ext_s
                                               INNER JOIN alert_default.speciality int_s
                                                  ON (ext_s.id_content = int_s.id_content AND
                                                     int_s.flg_available = g_flg_available)
                                               WHERE ext_s.flg_available = g_flg_available
                                                 AND int_s.id_speciality = src_tbl.id_link),
                                              0)) id_link
                              FROM alert_default.protocol_link src_tbl
                             INNER JOIN alert_default.protocol_mrk_vrs pmv
                                ON (pmv.id_protocol = src_tbl.id_protocol)
                             WHERE pmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND pmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                  -- speciality (PFH/CARE - different sources)
                               AND src_tbl.link_type = 'S'
                               AND ((src_tbl.id_link IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                          column_value
                                                           FROM TABLE(CAST(pk_backoffice_default.check_clinical_service_parent(i_lang,
                                                                                                                               src_tbl.id_link) AS
                                                                           table_number)) p) AND i_software(1) = 3) OR
                                   i_software(1) != 3)) temp_data
                     WHERE temp_data.id_protocol > 0
                    UNION
                    
                    SELECT temp_data.id_protocol, temp_data.link_type, temp_data.id_link
                      FROM (SELECT nvl((SELECT ext_p.id_protocol
                                         FROM protocol ext_p
                                        INNER JOIN alert_default.protocol int_p
                                           ON (int_p.id_content = ext_p.id_content)
                                        WHERE ext_p.flg_status = g_finished
                                          AND int_p.id_protocol = src_tbl.id_protocol),
                                       0) id_protocol,
                                   src_tbl.link_type,
                                   src_tbl.id_link
                              FROM alert_default.protocol_link src_tbl
                             INNER JOIN alert_default.protocol_mrk_vrs pmv
                                ON (pmv.id_protocol = src_tbl.id_protocol)
                             WHERE pmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND pmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                  -- diagnosis
                               AND src_tbl.link_type = 'H'
                               AND EXISTS (SELECT 0
                                      FROM diagnosis ext_tbl
                                     WHERE ext_tbl.id_diagnosis = src_tbl.id_link
                                       AND ext_tbl.flg_available = g_flg_available)) temp_data
                     WHERE temp_data.id_protocol > 0
                    UNION
                    
                    SELECT temp_data.id_protocol, temp_data.link_type, temp_data.id_link
                      FROM (SELECT src_tbl.rowid l_row,
                                   nvl((SELECT ext_p.id_protocol
                                         FROM protocol ext_p
                                        INNER JOIN alert_default.protocol int_p
                                           ON (int_p.id_content = ext_p.id_content)
                                        WHERE ext_p.flg_status = g_finished
                                          AND int_p.id_protocol = src_tbl.id_protocol),
                                       0) id_protocol,
                                   src_tbl.link_type,
                                   src_tbl.id_link
                              FROM alert_default.protocol_link src_tbl
                             INNER JOIN alert_default.protocol_mrk_vrs pmv
                                ON (pmv.id_protocol = src_tbl.id_protocol)
                             WHERE pmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND pmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                  -- protocol type
                               AND src_tbl.link_type = 'T'
                               AND EXISTS (SELECT 0
                                      FROM protocol_type ext_tbl
                                     WHERE ext_tbl.id_protocol_type = src_tbl.id_link
                                       AND ext_tbl.flg_available = g_flg_available)) temp_data
                     WHERE temp_data.id_protocol > 0) def_data
             WHERE NOT EXISTS (SELECT 0
                      FROM protocol_link dest_tbl
                     WHERE dest_tbl.id_protocol = def_data.id_protocol
                       AND dest_tbl.id_link = def_data.id_link
                       AND dest_tbl.link_type = def_data.link_type);
    
        o_result_tbl := SQL%ROWCOUNT;
        IF o_result_tbl > 0
        THEN
            g_cfg_done := 'TRUE';
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_protocol_link_search;
    FUNCTION set_protocol_question_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_protocol_question_search');
        INSERT INTO protocol_question
            (id_protocol_question, desc_protocol_question)
            SELECT id_protocol_question, desc_protocol_question
              FROM (SELECT id_protocol_question,
                           desc_protocol_question,
                           row_number() over(PARTITION BY id_protocol_question ORDER BY temp_data.l_row) records_count
                      FROM (SELECT src_tbl.rowid l_row, id_protocol_question, desc_protocol_question
                            -- decode FKS to dest_vals
                              FROM alert_default.protocol_question src_tbl
                             INNER JOIN alert_default.protocol_element pe
                                ON (pe.id_element = src_tbl.id_protocol_question AND pe.element_type = g_element_question)
                             INNER JOIN alert_default.protocol p
                                ON (p.id_protocol = pe.id_protocol)
                             WHERE EXISTS (SELECT 0
                                      FROM protocol ext_tbl
                                     WHERE ext_tbl.id_content = p.id_content
                                       AND ext_tbl.id_institution = i_institution)
                               AND pe.flg_available = g_flg_available) temp_data) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM protocol_question dest_tbl
                     WHERE dest_tbl.id_protocol_question = def_data.id_protocol_question);
        o_result_tbl := SQL%ROWCOUNT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_protocol_question_search;
    FUNCTION set_protocol_protocol_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_protocol_protocol_search');
        INSERT INTO protocol_protocol
            (id_protocol_protocol, desc_protocol_protocol, id_nested_protocol)
            SELECT def_data.id_protocol_protocol, def_data.desc_protocol_protocol, def_data.id_nested_protocol
              FROM (SELECT temp_data.id_protocol_protocol,
                           temp_data.desc_protocol_protocol,
                           temp_data.id_nested_protocol,
                           row_number() over(PARTITION BY temp_data.id_protocol_protocol ORDER BY temp_data.l_row) records_count
                      FROM (SELECT src_tbl.rowid l_row,
                                   src_tbl.id_protocol_protocol,
                                   src_tbl.desc_protocol_protocol,
                                   decode(src_tbl.id_nested_protocol,
                                          NULL,
                                          NULL,
                                          nvl((SELECT ext_p.id_protocol
                                                FROM protocol ext_p
                                               WHERE ext_p.id_content = p.id_content
                                                 AND ext_p.id_institution = i_institution),
                                              0)) id_nested_protocol
                            -- decode FKS to dest_vals
                              FROM alert_default.protocol_protocol src_tbl
                             INNER JOIN alert_default.protocol_element pe
                                ON (pe.id_element = src_tbl.id_protocol_protocol AND pe.element_type = g_element_protocol)
                             INNER JOIN alert_default.protocol p
                                ON (p.id_protocol = pe.id_protocol)
                             WHERE pe.flg_available = g_flg_available) temp_data
                     WHERE (temp_data.id_nested_protocol > 0 OR temp_data.id_nested_protocol IS NULL)) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM protocol_protocol dest_tbl
                     WHERE dest_tbl.id_protocol_protocol = def_data.id_protocol_protocol);
        o_result_tbl := SQL%ROWCOUNT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_protocol_protocol_search;
    FUNCTION set_protocol_text_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_protocol_text_search');
        INSERT INTO protocol_text
            (id_protocol_text, desc_protocol_text, protocol_text_type)
            SELECT def_data.id_protocol_text, def_data.desc_protocol_text, def_data.protocol_text_type
              FROM (SELECT temp_data.id_protocol_text,
                           temp_data.desc_protocol_text,
                           temp_data.protocol_text_type,
                           row_number() over(PARTITION BY temp_data.id_protocol_text ORDER BY temp_data.l_row) records_count
                      FROM (SELECT src_tbl.rowid l_row,
                                   src_tbl.id_protocol_text,
                                   src_tbl.desc_protocol_text,
                                   src_tbl.protocol_text_type
                            -- decode FKS to dest_vals
                              FROM alert_default.protocol_text src_tbl
                             INNER JOIN alert_default.protocol_element pe
                                ON (pe.id_element = src_tbl.id_protocol_text AND
                                   pe.element_type = src_tbl.protocol_text_type)
                             INNER JOIN alert_default.protocol p
                                ON (p.id_protocol = pe.id_protocol)
                             WHERE EXISTS (SELECT 0
                                      FROM protocol ext_tbl
                                     WHERE ext_tbl.id_content = p.id_content
                                       AND ext_tbl.id_institution = i_institution)
                               AND pe.flg_available = g_flg_available) temp_data) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM protocol_text dest_tbl
                     WHERE dest_tbl.id_protocol_text = def_data.id_protocol_text);
        o_result_tbl := SQL%ROWCOUNT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_protocol_text_search;
    FUNCTION set_protocol_element_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_protocol_element_search');
        INSERT INTO protocol_element
            (id_protocol_element,
             id_protocol,
             id_element,
             element_type,
             desc_element,
             x_coordinate,
             y_coordinate,
             flg_available)
            SELECT seq_protocol_element.nextval,
                   def_data.id_protocol,
                   def_data.id_element,
                   def_data.element_type,
                   def_data.desc_element,
                   def_data.x_coordinate,
                   def_data.y_coordinate,
                   def_data.flg_available
              FROM (SELECT temp_data.id_protocol,
                           temp_data.id_element,
                           element_type,
                           temp_data.desc_element,
                           temp_data.x_coordinate,
                           temp_data.y_coordinate,
                           temp_data.flg_available,
                           row_number() over(PARTITION BY temp_data.id_protocol, temp_data.id_element, element_type
                           
                           ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT ext_p.id_protocol
                                         FROM protocol ext_p
                                        WHERE ext_p.id_content = p.id_content
                                          AND ext_p.id_institution = i_institution),
                                       0) id_protocol,
                                   src_tbl.id_element,
                                   src_tbl.element_type,
                                   src_tbl.desc_element,
                                   src_tbl.x_coordinate,
                                   src_tbl.y_coordinate,
                                   src_tbl.flg_available,
                                   pmv.id_market,
                                   pmv.version
                            -- decode FKS to dest_vals
                              FROM alert_default.protocol_element src_tbl
                             INNER JOIN alert_default.protocol p
                                ON (p.id_protocol = src_tbl.id_protocol)
                             INNER JOIN alert_default.protocol_mrk_vrs pmv
                                ON (pmv.id_protocol = p.id_protocol)
                             WHERE pmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND pmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND src_tbl.flg_available = g_flg_available) temp_data
                     WHERE temp_data.id_protocol > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM protocol_element dest_tbl
                     WHERE dest_tbl.id_protocol = def_data.id_protocol
                       AND dest_tbl.id_element = def_data.id_element
                       AND dest_tbl.element_type = def_data.element_type
                       AND dest_tbl.x_coordinate = def_data.x_coordinate
                       AND dest_tbl.y_coordinate = def_data.y_coordinate);
        o_result_tbl := SQL%ROWCOUNT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_protocol_element_search;
    FUNCTION set_inst_protocol_task
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_protocol_def     protocol_element.id_protocol%TYPE := NULL;
        l_id_protocol         protocol_element.id_protocol%TYPE := NULL;
        l_id_content_def      protocol.id_content%TYPE := NULL;
        l_id_protocol_task    protocol_task.id_protocol_task%TYPE := NULL;
        l_id_group_task       protocol_task.id_group_task%TYPE := NULL;
        l_descr_protocol_task protocol_task.desc_protocol_task%TYPE := NULL;
        l_id_task_link        protocol_task.id_task_link%TYPE := NULL;
        l_task_type           protocol_task.task_type%TYPE := NULL;
        l_task_notes          protocol_task.task_notes%TYPE := NULL;
        l_id_task_attach      protocol_task.id_task_attach%TYPE := NULL;
        l_task_codif          protocol_task.task_codification%TYPE := NULL;
    
        l_id_protocol_task_array    table_number := table_number();
        l_id_group_task_array       table_number := table_number();
        l_descr_protocol_task_array table_varchar := table_varchar();
        l_id_task_link_array        table_number := table_number();
        l_task_type_array           table_number := table_number();
        l_task_notes_array          table_varchar := table_varchar();
        l_id_task_attach_array      table_number := table_number();
        l_task_codif_array          table_number := table_number();
    
        l_var_t VARCHAR2(1) := pk_protocol.g_element_task;
    
        l_count NUMBER := 0;
        l_index NUMBER := 1;
    
        --> Tasks Types
        l_var_analysis NUMBER := pk_protocol.g_task_analysis; -- Analises := 1;
        l_var_appoint  NUMBER := pk_protocol.g_task_appoint; -- Consultas := 2;
        l_var_img      NUMBER := pk_protocol.g_task_img; -- Imagem: exam := 4;
        l_var_enfint   NUMBER := pk_protocol.g_task_enfint; -- Intervenções de enfermagem := 6;
        --l_var_drug           NUMBER := pk_protocol.g_task_drug; -- Medicação : drug / tabelas infarmed := 7;
        l_var_otherexam NUMBER := pk_protocol.g_task_otherexam; -- Outros exames : exam := 8;
        l_var_spec      NUMBER := pk_protocol.g_task_spec; -- Pareceres : speciality := 9;
        --l_var_drug_ext       NUMBER := pk_protocol.g_task_drug_ext; -- Medicação exterior := 11;
        l_var_proc           NUMBER := pk_protocol.g_task_proc; -- Procedimentos := 12;
        l_var_monitorization NUMBER := pk_protocol.g_task_monitorization; -- monitorizacoes := 14;
        --PAT EDUC
        l_var_pat_educ NUMBER := pk_protocol.g_task_patient_education;
    
        --Analysis
        l_id_analysis_def analysis.id_content%TYPE := NULL;
        l_id_analysis     analysis.id_analysis%TYPE := NULL;
        l_asys_codif      analysis_codification.id_analysis_codification%TYPE := NULL;
        --Appointment
        l_id_clin_serv_def clinical_service.id_content%TYPE := NULL;
        l_id_clin_serv     clinical_service.id_clinical_service%TYPE := NULL;
        l_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE := NULL;
        --ICNP Composition
        l_id_icnp_def icnp_composition.id_content%TYPE := NULL;
        l_id_icnp     icnp_composition.id_composition%TYPE := NULL;
        --Exams
        l_id_exam_img_def   exam.id_content%TYPE := NULL;
        l_id_exam_img       exam.id_exam%TYPE := NULL;
        l_exam_img          exam.flg_type%TYPE := pk_exam_constant.g_type_img;
        l_id_exam_other_def exam.id_content%TYPE := NULL;
        l_id_exam_other     exam.id_exam%TYPE := NULL;
        l_exam_other        exam.flg_type%TYPE := pk_exam_constant.g_type_exm;
        l_exam_img_codif    exam_codification.id_exam_codification%TYPE := NULL;
        l_exam_other_codif  exam_codification.id_exam_codification%TYPE := NULL;
        --Medication
        --g_config_prescription_type sys_config.id_sys_config%TYPE := 'PRESCRIPTION_TYPE';
        --l_id_drug mi_med.id_drug%TYPE := NULL;
        --l_emb_id  me_med.emb_id%TYPE := NULL;
        --Speciality
        l_id_spec speciality.id_speciality%TYPE;
        --Procedures
        l_id_intervention_def intervention.id_content%TYPE := NULL;
        l_id_intervention     intervention.id_intervention%TYPE := NULL;
        l_interv_codif        interv_codification.id_interv_codification%TYPE := NULL;
        --Vital_Sign
        l_id_vital_sign vital_sign.id_vital_sign%TYPE;
        l_count_vsi     NUMBER := 0;
    
        --PAT EDUC
        l_id_pat_educ nurse_tea_topic.id_nurse_tea_topic%TYPE;
    
        CURSOR c_protocol_task IS
            SELECT DISTINCT pe.id_protocol,
                            p.id_content,
                            pt.id_protocol_task,
                            pt.id_group_task,
                            pt.desc_protocol_task,
                            pt.id_task_link,
                            pt.task_type,
                            pt.task_notes,
                            pt.id_task_attach,
                            pt.task_codification
              FROM alert_default.protocol_task pt
             INNER JOIN alert_default.protocol_element pe
                ON (pe.id_element = pt.id_group_task AND pe.element_type = l_var_t)
             INNER JOIN alert_default.protocol p
                ON (p.id_protocol = pe.id_protocol)
             INNER JOIN alert_default.protocol_mrk_vrs pmv
                ON (pmv.id_protocol = pe.id_protocol)
             WHERE pmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                      column_value
                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
               AND pmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                    column_value
                                     FROM TABLE(CAST(i_vers AS table_varchar)) p);
    
        CURSOR c_analysis(c_id_task_link IN guideline_task_link.id_task_link%TYPE) IS
            SELECT DISTINCT a.id_content
              FROM alert_default.analysis a
              JOIN alert_default.analysis_mrk_vrs amv
                ON (amv.id_analysis = a.id_analysis)
              JOIN alert_default.analysis_instit_soft ais
                ON (ais.id_analysis = a.id_analysis AND ais.flg_available = g_flg_available AND
                   ais.flg_type = pk_alert_constant.g_analysis_request)
             WHERE a.flg_available = g_flg_available
               AND a.id_analysis = c_id_task_link
               AND amv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                      column_value
                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
               AND amv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                    column_value
                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)
               AND ais.id_software IN (SELECT /*+ dynamic_sampling(p 2)*/
                                        column_value
                                         FROM TABLE(CAST(i_software AS table_varchar)) p);
    
        CURSOR c_appointment(c_id_task_link IN guideline_task_link.id_task_link%TYPE) IS
            SELECT cs.id_content
              FROM alert_default.clinical_service cs
             WHERE cs.flg_available = g_flg_available
               AND cs.id_clinical_service IN
                   (SELECT /*+ dynamic_sampling(p 2)*/
                     column_value
                      FROM TABLE(CAST(pk_backoffice_default.check_clinical_service_parent(i_lang, c_id_task_link) AS
                                      table_number)) p);
    
        CURSOR c_icnp(c_id_task_link IN guideline_task_link.id_task_link%TYPE) IS
            SELECT DISTINCT i.id_content
              FROM alert_default.icnp_composition i
              JOIN alert_default.icnp_compo_cs ic
                ON (ic.id_composition = i.id_composition)
              JOIN alert_default.clinical_service cs
                ON (cs.id_clinical_service = ic.id_clinical_service AND cs.flg_available = g_flg_available)
             WHERE i.flg_available = g_flg_available
               AND i.flg_type = 'A'
               AND i.id_composition = c_id_task_link
               AND ic.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
               AND ic.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                   column_value
                                    FROM TABLE(CAST(i_vers AS table_varchar)) p)
                  
               AND ic.id_software IN (SELECT /*+ dynamic_sampling(p 2)*/
                                       column_value
                                        FROM TABLE(CAST(i_software AS table_varchar)) p);
    
        CURSOR c_exams
        (
            c_id_task_link IN guideline_task_link.id_task_link%TYPE,
            c_exam_type    exam.flg_type%TYPE
        ) IS
            SELECT DISTINCT e.id_content
              FROM alert_default.exam e
              JOIN alert_default.exam_mrk_vrs emv
                ON (emv.id_exam = e.id_exam)
              JOIN alert_default.exam_clin_serv ecs
                ON (ecs.id_exam = e.id_exam AND ecs.flg_type = pk_exam_constant.g_exam_can_req)
             WHERE e.flg_available = g_flg_available
               AND e.id_exam = c_id_task_link
               AND e.flg_type = c_exam_type
               AND emv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                      column_value
                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
               AND emv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                    column_value
                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)
               AND ecs.id_software IN (SELECT /*+ dynamic_sampling(p 2)*/
                                        column_value
                                         FROM TABLE(CAST(i_software AS table_varchar)) p);
    
        CURSOR c_intervention(c_id_task_link IN guideline_task_link.id_task_link%TYPE) IS
            SELECT DISTINCT i.id_content
              FROM alert_default.intervention i
              JOIN alert_default.interv_mrk_vrs imv
                ON (imv.id_intervention = i.id_intervention)
              JOIN alert_default.interv_clin_serv ics
                ON (i.id_intervention = i.id_intervention AND ics.flg_type = pk_alert_constant.g_interv_can_req)
             WHERE i.flg_status = pk_alert_constant.g_active
               AND i.id_intervention = c_id_task_link
               AND imv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                      column_value
                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
               AND imv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                    column_value
                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)
               AND ics.id_software IN (SELECT /*+ dynamic_sampling(p 2)*/
                                        column_value
                                         FROM TABLE(CAST(i_software AS table_varchar)) p);
    
        CURSOR c_vital_sign(c_id_task_link IN guideline_task_link.id_task_link%TYPE) IS
            SELECT DISTINCT vs.id_vital_sign
              FROM vital_sign vs
              JOIN alert_default.vs_soft_inst vsi
                ON (vsi.id_vital_sign = vs.id_vital_sign AND vsi.flg_view = 'V2')
             WHERE vs.flg_available = g_flg_available
               AND vs.id_vital_sign = c_id_task_link
               AND vsi.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                      column_value
                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
               AND vsi.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                    column_value
                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)
               AND vsi.id_software IN (SELECT /*+ dynamic_sampling(p 2)*/
                                        column_value
                                         FROM TABLE(CAST(i_software AS table_varchar)) p);
    
        CURSOR c_prot_task
        (
            c_element_type      IN alert_default.protocol_element.element_type%TYPE,
            c_id_protocol       IN alert_default.protocol_element.id_protocol%TYPE,
            c_id_task_link      IN alert_default.protocol_task.id_task_link%TYPE,
            c_task_type         IN alert_default.protocol_task.task_type%TYPE,
            c_id_task_attach    IN alert_default.protocol_task.id_task_attach%TYPE,
            c_task_codification IN alert_default.protocol_task.task_codification%TYPE
        ) IS
            SELECT COUNT(pt.id_protocol_task)
              INTO l_count
              FROM alert_default.protocol_task pt
              JOIN alert_default.protocol_element pe
                ON (pe.id_element = pt.id_group_task AND pe.element_type = c_element_type)
             WHERE pe.id_protocol = c_id_protocol
               AND pt.id_task_link = c_id_task_link
               AND pt.task_type = c_task_type
               AND pt.id_task_attach = c_id_task_attach
               AND pt.task_codification = c_task_codification;
    BEGIN
        g_func_name := 'GET_INST_PROTOCOL_TASK ';
    
        g_error := 'OPEN C_PROTOCOL_TASK CURSOR';
        pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
        OPEN c_protocol_task;
        LOOP
            FETCH c_protocol_task
                INTO l_id_protocol_def,
                     l_id_content_def,
                     l_id_protocol_task,
                     l_id_group_task,
                     l_descr_protocol_task,
                     l_id_task_link,
                     l_task_type,
                     l_task_notes,
                     l_id_task_attach,
                     l_task_codif;
            EXIT WHEN c_protocol_task%NOTFOUND;
        
            g_error := 'GET PROTOCOL_ID';
            pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
            SELECT nvl((SELECT p.id_protocol
                         FROM protocol p
                        WHERE p.id_content = l_id_content_def
                          AND p.id_content IS NOT NULL
                          AND p.id_institution = i_institution
                          AND rownum = 1),
                       0)
              INTO l_id_protocol
              FROM dual;
        
            IF l_id_protocol != 0
            THEN
            
                --> PAT EDUCATION 
                IF l_task_type = l_var_pat_educ
                
                --> Added by JM 10-04-2013  
                
                THEN
                    SELECT nvl((SELECT DISTINCT ntt.id_nurse_tea_topic
                                 FROM nurse_tea_topic ntt
                                WHERE ntt.flg_available = g_flg_available
                                  AND ntt.id_nurse_tea_topic = l_id_task_link
                                  AND rownum = 1),
                               0)
                      INTO l_id_pat_educ
                      FROM dual;
                
                    IF l_task_codif IS NULL
                    THEN
                        g_error := 'COUNT_TASK_PAT_EDUC';
                        pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                    
                        g_error := '2 OPEN C_PROT_TASK';
                        OPEN c_prot_task(c_element_type      => l_var_t,
                                         c_id_protocol       => l_id_protocol,
                                         c_id_task_link      => l_id_pat_educ,
                                         c_task_type         => l_task_type,
                                         c_id_task_attach    => l_id_task_attach,
                                         c_task_codification => l_task_codif);
                        FETCH c_prot_task
                            INTO l_count;
                        CLOSE c_prot_task;
                    
                        IF l_count = 0
                        THEN
                            l_id_protocol_task_array.extend;
                            l_id_group_task_array.extend;
                            l_descr_protocol_task_array.extend;
                            l_id_task_link_array.extend;
                            l_task_type_array.extend;
                            l_task_notes_array.extend;
                            l_id_task_attach_array.extend;
                            l_task_codif_array.extend;
                        
                            l_id_protocol_task_array(l_index) := l_id_protocol_task;
                            l_id_group_task_array(l_index) := l_id_group_task;
                            l_descr_protocol_task_array(l_index) := l_descr_protocol_task;
                            l_id_task_link_array(l_index) := l_id_analysis;
                            l_task_type_array(l_index) := l_task_type;
                            l_task_notes_array(l_index) := l_task_notes;
                            l_id_task_attach_array(l_index) := l_id_task_attach;
                            l_task_codif_array(l_index) := l_task_codif;
                        
                            l_index := l_index + 1;
                        END IF;
                    
                    END IF;
                END IF;
            
                --> ANALYSIS
                IF l_task_type = l_var_analysis
                THEN
                    OPEN c_analysis(l_id_task_link);
                    LOOP
                    
                        FETCH c_analysis
                            INTO l_id_analysis_def;
                        EXIT WHEN c_analysis%NOTFOUND;
                    
                        SELECT nvl((SELECT a.id_analysis
                                     FROM analysis a
                                    WHERE a.id_content = l_id_analysis_def
                                      AND a.id_content IS NOT NULL
                                      AND a.flg_available = g_flg_available
                                      AND rownum = 1),
                                   0)
                          INTO l_id_analysis
                          FROM dual;
                    
                        IF l_id_analysis != 0
                        THEN
                        
                            IF l_task_codif IS NOT NULL
                            THEN
                                SELECT nvl((SELECT ac.id_analysis_codification
                                             FROM analysis_codification ac
                                            WHERE ac.id_analysis = l_id_analysis
                                              AND ac.id_codification =
                                                  (SELECT t.id_codification
                                                     FROM codification t
                                                    WHERE t.id_content =
                                                          (SELECT b.id_content
                                                             FROM alert_default.codification b
                                                             JOIN alert_default.analysis_codification ac1
                                                               ON ac1.id_codification = b.id_codification
                                                              AND ac1.id_analysis =
                                                                  (SELECT an.id_analysis
                                                                     FROM alert_default.analysis an
                                                                    WHERE an.id_content = l_id_analysis_def
                                                                      AND an.flg_available = g_flg_available)
                                                              AND ac1.flg_available = g_flg_available)
                                                      AND t.flg_available = g_flg_available)
                                              AND ac.flg_available = g_flg_available
                                              AND rownum = 1),
                                           0)
                                  INTO l_asys_codif
                                  FROM dual;
                            
                                IF l_asys_codif != 0
                                THEN
                                
                                    g_error := '1 OPEN C_PROT_TASK';
                                    OPEN c_prot_task(c_element_type      => l_var_t,
                                                     c_id_protocol       => l_id_protocol,
                                                     c_id_task_link      => l_id_analysis,
                                                     c_task_type         => l_task_type,
                                                     c_id_task_attach    => l_id_task_attach,
                                                     c_task_codification => l_asys_codif);
                                    FETCH c_prot_task
                                        INTO l_count;
                                    CLOSE c_prot_task;
                                
                                    IF l_count = 0
                                    THEN
                                    
                                        l_id_protocol_task_array.extend;
                                        l_id_group_task_array.extend;
                                        l_descr_protocol_task_array.extend;
                                        l_id_task_link_array.extend;
                                        l_task_type_array.extend;
                                        l_task_notes_array.extend;
                                        l_id_task_attach_array.extend;
                                        l_task_codif_array.extend;
                                    
                                        l_id_protocol_task_array(l_index) := l_id_protocol_task;
                                        l_id_group_task_array(l_index) := l_id_group_task;
                                        l_descr_protocol_task_array(l_index) := l_descr_protocol_task;
                                        l_id_task_link_array(l_index) := l_id_analysis;
                                        l_task_type_array(l_index) := l_task_type;
                                        l_task_notes_array(l_index) := l_task_notes;
                                        l_id_task_attach_array(l_index) := l_id_task_attach;
                                        l_task_codif_array(l_index) := l_asys_codif;
                                    
                                        l_index := l_index + 1;
                                    END IF;
                                END IF;
                            ELSE
                                g_error := 'COUNT_TASK_ANALYSIS';
                                pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                            
                                g_error := '2 OPEN C_PROT_TASK';
                                OPEN c_prot_task(c_element_type      => l_var_t,
                                                 c_id_protocol       => l_id_protocol,
                                                 c_id_task_link      => l_id_analysis,
                                                 c_task_type         => l_task_type,
                                                 c_id_task_attach    => l_id_task_attach,
                                                 c_task_codification => l_task_codif);
                                FETCH c_prot_task
                                    INTO l_count;
                                CLOSE c_prot_task;
                            
                                IF l_count = 0
                                THEN
                                    l_id_protocol_task_array.extend;
                                    l_id_group_task_array.extend;
                                    l_descr_protocol_task_array.extend;
                                    l_id_task_link_array.extend;
                                    l_task_type_array.extend;
                                    l_task_notes_array.extend;
                                    l_id_task_attach_array.extend;
                                    l_task_codif_array.extend;
                                
                                    l_id_protocol_task_array(l_index) := l_id_protocol_task;
                                    l_id_group_task_array(l_index) := l_id_group_task;
                                    l_descr_protocol_task_array(l_index) := l_descr_protocol_task;
                                    l_id_task_link_array(l_index) := l_id_analysis;
                                    l_task_type_array(l_index) := l_task_type;
                                    l_task_notes_array(l_index) := l_task_notes;
                                    l_id_task_attach_array(l_index) := l_id_task_attach;
                                    l_task_codif_array(l_index) := l_task_codif;
                                
                                    l_index := l_index + 1;
                                END IF;
                            END IF;
                        END IF;
                    END LOOP;
                    g_error := 'CLOSE C_ANALYSIS CURSOR';
                    pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                    CLOSE c_analysis;
                    --> APPOINTMENT
                ELSIF l_task_type = l_var_appoint
                THEN
                    OPEN c_appointment(l_id_task_link);
                    LOOP
                        FETCH c_appointment
                            INTO l_id_clin_serv_def;
                        EXIT WHEN c_appointment%NOTFOUND;
                    
                        g_error := 'GET SUBSEQUENT APPOINTMENT';
                        pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                        IF l_id_clin_serv_def != -1 --> Consultas subsequentes
                        THEN
                            g_error := 'GET_CLINICAL_SERVICE_ID';
                            pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                            SELECT nvl((SELECT cs.id_clinical_service
                                         FROM clinical_service cs
                                        WHERE cs.id_content = l_id_clin_serv_def
                                          AND cs.id_content IS NOT NULL
                                          AND cs.flg_available = g_flg_available
                                          AND rownum = 1),
                                       0)
                              INTO l_id_clin_serv
                              FROM dual;
                        
                            IF l_id_clin_serv != 0
                            THEN
                                SELECT nvl((SELECT dcs.id_dep_clin_serv
                                             FROM dep_clin_serv dcs
                                             JOIN department d
                                               ON (d.id_department = dcs.id_department AND
                                                  d.flg_available = g_flg_available AND
                                                  d.id_software IN
                                                  (SELECT /*+ opt_estimate(p rows = 10)*/
                                                     column_value
                                                      FROM TABLE(CAST(i_software AS table_varchar)) p) AND
                                                  d.id_institution = i_institution)
                                             JOIN dept dp
                                               ON (dp.id_dept = d.id_dept)
                                              AND dp.id_institution = i_institution
                                             JOIN clinical_service cs
                                               ON (cs.id_clinical_service = dcs.id_clinical_service AND
                                                  cs.flg_available = g_flg_available AND
                                                  cs.id_clinical_service = l_id_clin_serv)
                                            WHERE dcs.flg_available = g_flg_available
                                              AND rownum = 1),
                                           0)
                                  INTO l_id_dep_clin_serv
                                  FROM dual;
                            
                                IF l_id_dep_clin_serv != 0
                                THEN
                                
                                    g_error := '3 OPEN C_PROT_TASK';
                                    OPEN c_prot_task(c_element_type      => l_var_t,
                                                     c_id_protocol       => l_id_protocol,
                                                     c_id_task_link      => l_id_dep_clin_serv,
                                                     c_task_type         => l_task_type,
                                                     c_id_task_attach    => l_id_task_attach,
                                                     c_task_codification => l_task_codif);
                                    FETCH c_prot_task
                                        INTO l_count;
                                    CLOSE c_prot_task;
                                
                                    IF l_count = 0
                                    THEN
                                        l_id_protocol_task_array.extend;
                                        l_id_group_task_array.extend;
                                        l_descr_protocol_task_array.extend;
                                        l_id_task_link_array.extend;
                                        l_task_type_array.extend;
                                        l_task_notes_array.extend;
                                        l_id_task_attach_array.extend;
                                        l_task_codif_array.extend;
                                    
                                        l_id_protocol_task_array(l_index) := l_id_protocol_task;
                                        l_id_group_task_array(l_index) := l_id_group_task;
                                        l_descr_protocol_task_array(l_index) := l_descr_protocol_task;
                                        l_id_task_link_array(l_index) := l_id_dep_clin_serv;
                                        l_task_type_array(l_index) := l_task_type;
                                        l_task_notes_array(l_index) := l_task_notes;
                                        l_id_task_attach_array(l_index) := l_id_task_attach;
                                        l_task_codif_array(l_index) := l_task_codif;
                                    
                                        l_index := l_index + 1;
                                    END IF;
                                END IF;
                            END IF;
                        ELSE
                        
                            g_error := '4 OPEN C_PROT_TASK';
                            OPEN c_prot_task(c_element_type      => l_var_t,
                                             c_id_protocol       => l_id_protocol,
                                             c_id_task_link      => -1,
                                             c_task_type         => l_task_type,
                                             c_id_task_attach    => l_id_task_attach,
                                             c_task_codification => l_task_codif);
                            FETCH c_prot_task
                                INTO l_count;
                            CLOSE c_prot_task;
                        
                            IF l_count = 0
                            THEN
                                l_id_protocol_task_array.extend;
                                l_id_group_task_array.extend;
                                l_descr_protocol_task_array.extend;
                                l_id_task_link_array.extend;
                                l_task_type_array.extend;
                                l_task_notes_array.extend;
                                l_id_task_attach_array.extend;
                                l_task_codif_array.extend;
                            
                                l_id_protocol_task_array(l_index) := l_id_protocol_task;
                                l_id_group_task_array(l_index) := l_id_group_task;
                                l_descr_protocol_task_array(l_index) := l_descr_protocol_task;
                                l_id_task_link_array(l_index) := -1;
                                l_task_type_array(l_index) := l_task_type;
                                l_task_notes_array(l_index) := l_task_notes;
                                l_id_task_attach_array(l_index) := l_id_task_attach;
                                l_task_codif_array(l_index) := l_task_codif;
                            
                                l_index := l_index + 1;
                            END IF;
                        
                        END IF;
                    END LOOP;
                    g_error := 'CLOSE C_APPOINTMENT CURSOR';
                    pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                    CLOSE c_appointment;
                    --> ICNP_COMPOSITION
                ELSIF l_task_type = l_var_enfint
                THEN
                    OPEN c_icnp(l_id_task_link);
                    LOOP
                        FETCH c_icnp
                            INTO l_id_icnp_def;
                        EXIT WHEN c_icnp%NOTFOUND;
                    
                        g_error := 'GET_ICNP_COMPOSITION_ID';
                        pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                        SELECT nvl((SELECT ic.id_composition
                                     FROM icnp_composition ic
                                    WHERE ic.id_content = l_id_icnp_def
                                      AND ic.id_content IS NOT NULL
                                      AND ic.flg_available = g_flg_available
                                      AND ic.flg_type = 'A'
                                      AND rownum = 1),
                                   0)
                          INTO l_id_icnp
                          FROM dual;
                    
                        IF l_id_icnp != 0
                        THEN
                            g_error := '5 OPEN C_PROT_TASK';
                            OPEN c_prot_task(c_element_type      => l_var_t,
                                             c_id_protocol       => l_id_protocol,
                                             c_id_task_link      => l_id_icnp,
                                             c_task_type         => l_task_type,
                                             c_id_task_attach    => l_id_task_attach,
                                             c_task_codification => l_task_codif);
                            FETCH c_prot_task
                                INTO l_count;
                            CLOSE c_prot_task;
                        
                            IF l_count = 0
                            THEN
                                l_id_protocol_task_array.extend;
                                l_id_group_task_array.extend;
                                l_descr_protocol_task_array.extend;
                                l_id_task_link_array.extend;
                                l_task_type_array.extend;
                                l_task_notes_array.extend;
                                l_id_task_attach_array.extend;
                                l_task_codif_array.extend;
                            
                                l_id_protocol_task_array(l_index) := l_id_protocol_task;
                                l_id_group_task_array(l_index) := l_id_group_task;
                                l_descr_protocol_task_array(l_index) := l_descr_protocol_task;
                                l_id_task_link_array(l_index) := l_id_icnp;
                                l_task_type_array(l_index) := l_task_type;
                                l_task_notes_array(l_index) := l_task_notes;
                                l_id_task_attach_array(l_index) := l_id_task_attach;
                                l_task_codif_array(l_index) := l_task_codif;
                            
                                l_index := l_index + 1;
                            END IF;
                        END IF;
                    END LOOP;
                    g_error := 'CLOSE C_ICNP CURSOR';
                    pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                    CLOSE c_icnp;
                    --> EXAM_IMG
                ELSIF l_task_type = l_var_img
                THEN
                    OPEN c_exams(l_id_task_link, l_exam_img);
                    LOOP
                        FETCH c_exams
                            INTO l_id_exam_img_def;
                        EXIT WHEN c_exams%NOTFOUND;
                    
                        g_error := 'GET_EXAM_IMG_ID';
                        pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                        SELECT nvl((SELECT e.id_exam
                                     FROM exam e
                                    WHERE e.id_content = l_id_exam_img_def
                                      AND e.id_content IS NOT NULL
                                      AND e.flg_available = g_flg_available
                                      AND e.flg_type = l_exam_img
                                      AND rownum = 1),
                                   0)
                          INTO l_id_exam_img
                          FROM dual;
                    
                        IF l_id_exam_img != 0
                        THEN
                        
                            IF l_task_codif IS NOT NULL
                            THEN
                                SELECT nvl((SELECT ec.id_exam_codification
                                             FROM exam_codification ec
                                            WHERE ec.id_exam = l_id_exam_img
                                              AND ec.id_codification =
                                                  (SELECT t.id_codification
                                                     FROM codification t
                                                    WHERE t.id_content =
                                                          (SELECT b.id_content
                                                             FROM alert_default.codification b
                                                             JOIN alert_default.exam_codification ec1
                                                               ON ec1.id_codification = b.id_codification
                                                              AND ec1.id_exam =
                                                                  (SELECT e.id_exam
                                                                     FROM alert_default.exam e
                                                                    WHERE e.id_content = l_id_exam_img_def
                                                                      AND e.flg_type = l_exam_img
                                                                      AND e.flg_available = g_flg_available)
                                                              AND ec1.flg_available = g_flg_available)
                                                      AND t.flg_available = g_flg_available)
                                              AND ec.flg_available = g_flg_available
                                              AND rownum = 1),
                                           0)
                                  INTO l_exam_img_codif
                                  FROM dual;
                            
                                IF l_exam_img_codif != 0
                                THEN
                                
                                    g_error := '6 OPEN C_PROT_TASK';
                                    OPEN c_prot_task(c_element_type      => l_var_t,
                                                     c_id_protocol       => l_id_protocol,
                                                     c_id_task_link      => l_id_exam_img,
                                                     c_task_type         => l_task_type,
                                                     c_id_task_attach    => l_id_task_attach,
                                                     c_task_codification => l_exam_img_codif);
                                    FETCH c_prot_task
                                        INTO l_count;
                                    CLOSE c_prot_task;
                                
                                    IF l_count = 0
                                    THEN
                                        l_id_protocol_task_array.extend;
                                        l_id_group_task_array.extend;
                                        l_descr_protocol_task_array.extend;
                                        l_id_task_link_array.extend;
                                        l_task_type_array.extend;
                                        l_task_notes_array.extend;
                                        l_id_task_attach_array.extend;
                                        l_task_codif_array.extend;
                                    
                                        l_id_protocol_task_array(l_index) := l_id_protocol_task;
                                        l_id_group_task_array(l_index) := l_id_group_task;
                                        l_descr_protocol_task_array(l_index) := l_descr_protocol_task;
                                        l_id_task_link_array(l_index) := l_id_exam_img;
                                        l_task_type_array(l_index) := l_task_type;
                                        l_task_notes_array(l_index) := l_task_notes;
                                        l_id_task_attach_array(l_index) := l_id_task_attach;
                                        l_task_codif_array(l_index) := l_exam_img_codif;
                                    
                                        l_index := l_index + 1;
                                    END IF;
                                END IF;
                            ELSE
                                g_error := '7 OPEN C_PROT_TASK';
                                OPEN c_prot_task(c_element_type      => l_var_t,
                                                 c_id_protocol       => l_id_protocol,
                                                 c_id_task_link      => l_id_exam_img,
                                                 c_task_type         => l_task_type,
                                                 c_id_task_attach    => l_id_task_attach,
                                                 c_task_codification => l_task_codif);
                                FETCH c_prot_task
                                    INTO l_count;
                                CLOSE c_prot_task;
                            
                                IF l_count = 0
                                THEN
                                    l_id_protocol_task_array.extend;
                                    l_id_group_task_array.extend;
                                    l_descr_protocol_task_array.extend;
                                    l_id_task_link_array.extend;
                                    l_task_type_array.extend;
                                    l_task_notes_array.extend;
                                    l_id_task_attach_array.extend;
                                    l_task_codif_array.extend;
                                
                                    l_id_protocol_task_array(l_index) := l_id_protocol_task;
                                    l_id_group_task_array(l_index) := l_id_group_task;
                                    l_descr_protocol_task_array(l_index) := l_descr_protocol_task;
                                    l_id_task_link_array(l_index) := l_id_exam_img;
                                    l_task_type_array(l_index) := l_task_type;
                                    l_task_notes_array(l_index) := l_task_notes;
                                    l_id_task_attach_array(l_index) := l_id_task_attach;
                                    l_task_codif_array(l_index) := l_task_codif;
                                
                                    l_index := l_index + 1;
                                END IF;
                            END IF;
                        END IF;
                    END LOOP;
                    g_error := 'CLOSE C_EXAMS CURSOR';
                    pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                    CLOSE c_exams;
                    --> EXAM_OTHER
                ELSIF l_task_type = l_var_otherexam
                THEN
                    OPEN c_exams(l_id_task_link, l_exam_other);
                    LOOP
                        FETCH c_exams
                            INTO l_id_exam_other_def;
                        EXIT WHEN c_exams%NOTFOUND;
                    
                        g_error := 'GET_EXAM_OTHER_ID';
                        pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                        SELECT nvl((SELECT e.id_exam
                                     FROM exam e
                                    WHERE e.id_content = l_id_exam_other_def
                                      AND e.id_content IS NOT NULL
                                      AND e.flg_available = g_flg_available
                                      AND e.flg_type = l_exam_other
                                      AND rownum = 1),
                                   0)
                          INTO l_id_exam_other
                          FROM dual;
                    
                        IF l_id_exam_other != 0
                        THEN
                        
                            IF l_task_codif IS NOT NULL
                            THEN
                                SELECT nvl((SELECT ec.id_exam_codification
                                             FROM exam_codification ec
                                            WHERE ec.id_exam = l_id_exam_other
                                              AND ec.id_codification =
                                                  (SELECT t.id_codification
                                                     FROM codification t
                                                    WHERE t.id_content =
                                                          (SELECT b.id_content
                                                             FROM alert_default.codification b
                                                             JOIN alert_default.exam_codification ec1
                                                               ON ec1.id_codification = b.id_codification
                                                              AND ec1.id_exam =
                                                                  (SELECT e.id_exam
                                                                     FROM alert_default.exam e
                                                                    WHERE e.id_content = l_id_exam_other_def
                                                                      AND e.flg_type = l_exam_other
                                                                      AND e.flg_available = g_flg_available)
                                                              AND ec1.flg_available = g_flg_available)
                                                      AND t.flg_available = g_flg_available)
                                              AND ec.flg_available = g_flg_available
                                              AND rownum = 1),
                                           0)
                                  INTO l_exam_other_codif
                                  FROM dual;
                            
                                IF l_exam_other_codif != 0
                                THEN
                                
                                    g_error := '8 OPEN C_PROT_TASK';
                                    OPEN c_prot_task(c_element_type      => l_var_t,
                                                     c_id_protocol       => l_id_protocol,
                                                     c_id_task_link      => l_id_exam_img,
                                                     c_task_type         => l_task_type,
                                                     c_id_task_attach    => l_id_task_attach,
                                                     c_task_codification => l_exam_other_codif);
                                    FETCH c_prot_task
                                        INTO l_count;
                                    CLOSE c_prot_task;
                                
                                    IF l_count = 0
                                    THEN
                                        l_id_protocol_task_array.extend;
                                        l_id_group_task_array.extend;
                                        l_descr_protocol_task_array.extend;
                                        l_id_task_link_array.extend;
                                        l_task_type_array.extend;
                                        l_task_notes_array.extend;
                                        l_id_task_attach_array.extend;
                                        l_task_codif_array.extend;
                                    
                                        l_id_protocol_task_array(l_index) := l_id_protocol_task;
                                        l_id_group_task_array(l_index) := l_id_group_task;
                                        l_descr_protocol_task_array(l_index) := l_descr_protocol_task;
                                        l_id_task_link_array(l_index) := l_id_exam_img;
                                        l_task_type_array(l_index) := l_task_type;
                                        l_task_notes_array(l_index) := l_task_notes;
                                        l_id_task_attach_array(l_index) := l_id_task_attach;
                                        l_task_codif_array(l_index) := l_exam_other_codif;
                                    
                                        l_index := l_index + 1;
                                    END IF;
                                END IF;
                            ELSE
                                g_error := '9 OPEN C_PROT_TASK';
                                OPEN c_prot_task(c_element_type      => l_var_t,
                                                 c_id_protocol       => l_id_protocol,
                                                 c_id_task_link      => l_id_exam_img,
                                                 c_task_type         => l_task_type,
                                                 c_id_task_attach    => l_id_task_attach,
                                                 c_task_codification => l_task_codif);
                                FETCH c_prot_task
                                    INTO l_count;
                                CLOSE c_prot_task;
                            
                                IF l_count = 0
                                THEN
                                    l_id_protocol_task_array.extend;
                                    l_id_group_task_array.extend;
                                    l_descr_protocol_task_array.extend;
                                    l_id_task_link_array.extend;
                                    l_task_type_array.extend;
                                    l_task_notes_array.extend;
                                    l_id_task_attach_array.extend;
                                    l_task_codif_array.extend;
                                
                                    l_id_protocol_task_array(l_index) := l_id_protocol_task;
                                    l_id_group_task_array(l_index) := l_id_group_task;
                                    l_descr_protocol_task_array(l_index) := l_descr_protocol_task;
                                    l_id_task_link_array(l_index) := l_id_exam_img;
                                    l_task_type_array(l_index) := l_task_type;
                                    l_task_notes_array(l_index) := l_task_notes;
                                    l_id_task_attach_array(l_index) := l_id_task_attach;
                                    l_task_codif_array(l_index) := l_task_codif;
                                
                                    l_index := l_index + 1;
                                END IF;
                            END IF;
                        END IF;
                    END LOOP;
                    g_error := 'CLOSE C_EXAMS CURSOR';
                    pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                    CLOSE c_exams;
                    --> New Medication need to be integrated
                    /*ELSIF l_task_type = l_var_drug
                    THEN
                        g_error := 'PK_SYSCONFIG.GET_CONFIG PRESCRIPTION_TYPE ' || i_institution;
                        SELECT nvl((SELECT pk_sysconfig.get_config(g_config_prescription_type,
                                                                  profissional(NULL, i_institution, i_software))
                                     FROM dual),
                                   NULL)
                          INTO g_config_prescription_type
                          FROM dual;
                    
                        g_error := 'SELECT ID_DRUG ' || g_config_prescription_type;
                        BEGIN
                            SELECT DISTINCT t.id_drug
                              INTO l_id_drug
                              FROM mi_med t
                              JOIN drug_dep_clin_serv dcs
                                ON (dcs.id_drug = t.id_drug AND dcs.id_institution = i_institution AND
                                   dcs.vers = g_config_prescription_type AND
                                   dcs.flg_type = pk_medication_types.c_ddcs_flg_type_pesq_p AND
                                   dcs.id_software = i_software)
                             WHERE t.flg_available = g_flg_available
                               AND t.flg_type = pk_guidelines.g_drug
                               AND t.vers = g_config_prescription_type
                               AND t.id_drug = l_id_task_link;
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_id_drug := NULL;
                        END;
                    
                        IF l_id_drug IS NOT NULL
                           AND g_config_prescription_type IS NOT NULL
                        THEN
                            g_error := '10 OPEN C_PROT_TASK';
                            OPEN c_prot_task(c_element_type      => l_var_t,
                                             c_id_protocol       => l_id_protocol,
                                             c_id_task_link      => l_id_drug,
                                             c_task_type         => l_task_type,
                                             c_id_task_attach    => l_id_task_attach,
                                             c_task_codification => l_task_codif);
                            FETCH c_prot_task
                                INTO l_count;
                            CLOSE c_prot_task;
                        
                            IF l_count = 0
                            THEN
                                l_id_protocol_task_array.extend;
                                l_id_group_task_array.extend;
                                l_descr_protocol_task_array.extend;
                                l_id_task_link_array.extend;
                                l_task_type_array.extend;
                                l_task_notes_array.extend;
                                l_id_task_attach_array.extend;
                                l_task_codif_array.extend;
                            
                                l_id_protocol_task_array(l_index) := l_id_protocol_task;
                                l_id_group_task_array(l_index) := l_id_group_task;
                                l_descr_protocol_task_array(l_index) := l_descr_protocol_task;
                                l_id_task_link_array(l_index) := l_id_drug;
                                l_task_type_array(l_index) := l_task_type;
                                l_task_notes_array(l_index) := l_task_notes;
                                l_id_task_attach_array(l_index) := l_id_task_attach;
                                l_task_codif_array(l_index) := l_task_codif;
                            
                                l_index := l_index + 1;
                            END IF;
                        END IF;
                        --> External_Medication
                    ELSIF l_task_type = l_var_drug_ext
                    THEN
                        g_error := 'PK_SYSCONFIG.GET_CONFIG PRESCRIPTION_TYPE ' || i_institution;
                        SELECT nvl((SELECT pk_sysconfig.get_config(g_config_prescription_type,
                                                                  profissional(NULL, i_institution, i_software))
                                     FROM dual),
                                   NULL)
                          INTO g_config_prescription_type
                          FROM dual;
                    
                        g_error := 'SELECT EMB_ID ' || g_config_prescription_type;
                        BEGIN
                            SELECT DISTINCT t.emb_id
                              INTO l_emb_id
                              FROM me_med t
                              JOIN emb_dep_clin_serv edcs
                                ON (edcs.emb_id = t.emb_id AND edcs.id_institution = i_institution AND
                                   edcs.vers = g_config_prescription_type AND
                                   edcs.flg_type = pk_medication_types.c_ddcs_flg_type_pesq_p AND
                                   edcs.id_software = i_software)
                             WHERE t.flg_available = g_flg_available
                               AND t.flg_comerc = g_flg_available
                               AND t.vers = g_config_prescription_type
                               AND t.emb_id = l_id_task_link;
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_emb_id := NULL;
                        END;
                    
                        IF l_emb_id IS NOT NULL
                           AND g_config_prescription_type IS NOT NULL
                        THEN
                        
                            g_error := '11 OPEN C_PROT_TASK';
                            OPEN c_prot_task(c_element_type      => l_var_t,
                                             c_id_protocol       => l_id_protocol,
                                             c_id_task_link      => l_emb_id,
                                             c_task_type         => l_task_type,
                                             c_id_task_attach    => l_id_task_attach,
                                             c_task_codification => l_task_codif);
                            FETCH c_prot_task
                                INTO l_count;
                            CLOSE c_prot_task;
                        
                            IF l_count = 0
                            THEN
                                l_id_protocol_task_array.extend;
                                l_id_group_task_array.extend;
                                l_descr_protocol_task_array.extend;
                                l_id_task_link_array.extend;
                                l_task_type_array.extend;
                                l_task_notes_array.extend;
                                l_id_task_attach_array.extend;
                                l_task_codif_array.extend;
                            
                                l_id_protocol_task_array(l_index) := l_id_protocol_task;
                                l_id_group_task_array(l_index) := l_id_group_task;
                                l_descr_protocol_task_array(l_index) := l_descr_protocol_task;
                                l_id_task_link_array(l_index) := l_emb_id;
                                l_task_type_array(l_index) := l_task_type;
                                l_task_notes_array(l_index) := l_task_notes;
                                l_id_task_attach_array(l_index) := l_id_task_attach;
                                l_task_codif_array(l_index) := l_task_codif;
                            
                                l_index := l_index + 1;
                            END IF;
                        END IF;*/
                    --> Speciality
                ELSIF l_task_type = l_var_spec
                THEN
                    g_error := 'GET_SPECIALITY_ID';
                    pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                    SELECT nvl((SELECT sp.id_speciality
                                 FROM speciality sp
                                WHERE sp.id_content = (SELECT sp1.id_content
                                                         FROM alert_default.speciality sp1
                                                        WHERE sp1.id_speciality = l_id_task_link
                                                          AND sp1.flg_available = g_flg_available)
                                  AND sp.id_content IS NOT NULL
                                  AND sp.flg_available = g_flg_available
                                  AND rownum = 1),
                               0)
                      INTO l_id_spec
                      FROM dual;
                
                    IF l_id_spec != 0
                    THEN
                    
                        g_error := '12 OPEN C_PROT_TASK';
                        OPEN c_prot_task(c_element_type      => l_var_t,
                                         c_id_protocol       => l_id_protocol,
                                         c_id_task_link      => l_id_spec,
                                         c_task_type         => l_task_type,
                                         c_id_task_attach    => l_id_task_attach,
                                         c_task_codification => l_task_codif);
                        FETCH c_prot_task
                            INTO l_count;
                        CLOSE c_prot_task;
                    
                        IF l_count = 0
                        THEN
                            l_id_protocol_task_array.extend;
                            l_id_group_task_array.extend;
                            l_descr_protocol_task_array.extend;
                            l_id_task_link_array.extend;
                            l_task_type_array.extend;
                            l_task_notes_array.extend;
                            l_id_task_attach_array.extend;
                            l_task_codif_array.extend;
                        
                            l_id_protocol_task_array(l_index) := l_id_protocol_task;
                            l_id_group_task_array(l_index) := l_id_group_task;
                            l_descr_protocol_task_array(l_index) := l_descr_protocol_task;
                            l_id_task_link_array(l_index) := l_id_spec;
                            l_task_type_array(l_index) := l_task_type;
                            l_task_notes_array(l_index) := l_task_notes;
                            l_id_task_attach_array(l_index) := l_id_task_attach;
                            l_task_codif_array(l_index) := l_task_codif;
                        
                            l_index := l_index + 1;
                        END IF;
                    END IF;
                    --> PROCEDURES
                ELSIF l_task_type = l_var_proc
                THEN
                    OPEN c_intervention(l_id_task_link);
                    LOOP
                        FETCH c_intervention
                            INTO l_id_intervention_def;
                        EXIT WHEN c_intervention%NOTFOUND;
                    
                        g_error := 'GET_INTERVENTION_ID';
                        pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                        SELECT nvl((SELECT i.id_intervention
                                     FROM intervention i
                                    WHERE i.id_content = l_id_intervention_def
                                      AND i.id_content IS NOT NULL
                                      AND i.flg_status = pk_alert_constant.g_active
                                      AND rownum = 1),
                                   0)
                          INTO l_id_intervention
                          FROM dual;
                    
                        IF l_id_intervention != 0
                        THEN
                            IF l_task_codif IS NOT NULL
                            THEN
                                SELECT nvl((SELECT ic.id_interv_codification
                                             FROM interv_codification ic
                                            WHERE ic.id_intervention = l_id_intervention
                                              AND ic.id_codification =
                                                  (SELECT t.id_codification
                                                     FROM codification t
                                                    WHERE t.id_content =
                                                          (SELECT b.id_content
                                                             FROM alert_default.codification b
                                                             JOIN alert_default.interv_codification ic1
                                                               ON ic1.id_codification = b.id_codification
                                                              AND ic1.id_intervention =
                                                                  (SELECT i.id_intervention
                                                                     FROM alert_default.intervention i
                                                                    WHERE i.id_intervention = l_id_task_link
                                                                      AND i.flg_status = pk_alert_constant.g_active)
                                                              AND ic1.flg_available = g_flg_available)
                                                      AND t.flg_available = g_flg_available)
                                              AND ic.flg_available = g_flg_available
                                              AND rownum = 1),
                                           0)
                                  INTO l_interv_codif
                                  FROM dual;
                            
                                IF l_interv_codif != 0
                                THEN
                                
                                    g_error := '13 OPEN C_PROT_TASK';
                                    OPEN c_prot_task(c_element_type      => l_var_t,
                                                     c_id_protocol       => l_id_protocol,
                                                     c_id_task_link      => l_id_intervention,
                                                     c_task_type         => l_task_type,
                                                     c_id_task_attach    => l_id_task_attach,
                                                     c_task_codification => l_interv_codif);
                                    FETCH c_prot_task
                                        INTO l_count;
                                    CLOSE c_prot_task;
                                
                                    IF l_count = 0
                                    THEN
                                        l_id_protocol_task_array.extend;
                                        l_id_group_task_array.extend;
                                        l_descr_protocol_task_array.extend;
                                        l_id_task_link_array.extend;
                                        l_task_type_array.extend;
                                        l_task_notes_array.extend;
                                        l_id_task_attach_array.extend;
                                        l_task_codif_array.extend;
                                    
                                        l_id_protocol_task_array(l_index) := l_id_protocol_task;
                                        l_id_group_task_array(l_index) := l_id_group_task;
                                        l_descr_protocol_task_array(l_index) := l_descr_protocol_task;
                                        l_id_task_link_array(l_index) := l_id_intervention;
                                        l_task_type_array(l_index) := l_task_type;
                                        l_task_notes_array(l_index) := l_task_notes;
                                        l_id_task_attach_array(l_index) := l_id_task_attach;
                                        l_task_codif_array(l_index) := l_interv_codif;
                                    
                                        l_index := l_index + 1;
                                    END IF;
                                END IF;
                            ELSE
                            
                                g_error := '14 OPEN C_PROT_TASK';
                                OPEN c_prot_task(c_element_type      => l_var_t,
                                                 c_id_protocol       => l_id_protocol,
                                                 c_id_task_link      => l_id_intervention,
                                                 c_task_type         => l_task_type,
                                                 c_id_task_attach    => l_id_task_attach,
                                                 c_task_codification => l_task_codif);
                                FETCH c_prot_task
                                    INTO l_count;
                                CLOSE c_prot_task;
                            
                                IF l_count = 0
                                THEN
                                    l_id_protocol_task_array.extend;
                                    l_id_group_task_array.extend;
                                    l_descr_protocol_task_array.extend;
                                    l_id_task_link_array.extend;
                                    l_task_type_array.extend;
                                    l_task_notes_array.extend;
                                    l_id_task_attach_array.extend;
                                    l_task_codif_array.extend;
                                
                                    l_id_protocol_task_array(l_index) := l_id_protocol_task;
                                    l_id_group_task_array(l_index) := l_id_group_task;
                                    l_descr_protocol_task_array(l_index) := l_descr_protocol_task;
                                    l_id_task_link_array(l_index) := l_id_intervention;
                                    l_task_type_array(l_index) := l_task_type;
                                    l_task_notes_array(l_index) := l_task_notes;
                                    l_id_task_attach_array(l_index) := l_id_task_attach;
                                    l_task_codif_array(l_index) := l_task_codif;
                                
                                    l_index := l_index + 1;
                                END IF;
                            END IF;
                        END IF;
                    END LOOP;
                    g_error := 'CLOSE C_INTERVENTION CURSOR';
                    pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                    CLOSE c_intervention;
                    --> Monitorizations
                ELSIF l_task_type = l_var_monitorization
                THEN
                    g_error := 'OPEN C_VITAL_SIGN ' || l_id_task_link;
                    OPEN c_vital_sign(l_id_task_link);
                    LOOP
                        g_error := 'FETCH C_VITAL_SIGN';
                        FETCH c_vital_sign
                            INTO l_id_vital_sign;
                        EXIT WHEN c_vital_sign%NOTFOUND;
                    
                        IF l_id_vital_sign != 0
                        THEN
                            g_error := 'CHECK VS_SOFT_INST FOR INSTITUTION';
                            pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                            SELECT COUNT(vsi.id_vs_soft_inst)
                              INTO l_count_vsi
                              FROM vs_soft_inst vsi
                             WHERE vsi.id_vital_sign = l_id_vital_sign
                               AND vsi.id_institution = i_institution
                               AND vsi.id_software IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_varchar)) p)
                               AND vsi.flg_view = 'V2';
                        
                            IF l_count_vsi != 0
                            THEN
                            
                                g_error := '15 OPEN C_PROT_TASK';
                                OPEN c_prot_task(c_element_type      => l_var_t,
                                                 c_id_protocol       => l_id_protocol,
                                                 c_id_task_link      => l_id_vital_sign,
                                                 c_task_type         => l_task_type,
                                                 c_id_task_attach    => l_id_task_attach,
                                                 c_task_codification => l_task_codif);
                                FETCH c_prot_task
                                    INTO l_count;
                                CLOSE c_prot_task;
                            
                                IF l_count = 0
                                THEN
                                    l_id_protocol_task_array.extend;
                                    l_id_group_task_array.extend;
                                    l_descr_protocol_task_array.extend;
                                    l_id_task_link_array.extend;
                                    l_task_type_array.extend;
                                    l_task_notes_array.extend;
                                    l_id_task_attach_array.extend;
                                    l_task_codif_array.extend;
                                
                                    l_id_protocol_task_array(l_index) := l_id_protocol_task;
                                    l_id_group_task_array(l_index) := l_id_group_task;
                                    l_descr_protocol_task_array(l_index) := l_descr_protocol_task;
                                    l_id_task_link_array(l_index) := l_id_vital_sign;
                                    l_task_type_array(l_index) := l_task_type;
                                    l_task_notes_array(l_index) := l_task_notes;
                                    l_id_task_attach_array(l_index) := l_id_task_attach;
                                    l_task_codif_array(l_index) := l_task_codif;
                                
                                    l_index := l_index + 1;
                                END IF;
                            END IF;
                        END IF;
                    END LOOP;
                    g_error := 'CLOSE C_VITAL_SIGN CURSOR';
                    pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                    CLOSE c_vital_sign;
                
                END IF; --> fim de todas as tasks
            END IF;
        END LOOP;
        g_error := 'CLOSE C_PROTOCOL_TASK CURSOR';
        pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
        CLOSE c_protocol_task;
    
        FORALL r IN 1 .. l_id_protocol_task_array.count
            INSERT INTO protocol_task
                (id_protocol_task,
                 id_group_task,
                 desc_protocol_task,
                 task_type,
                 task_notes,
                 id_task_attach,
                 task_codification,
                 id_task_link)
            VALUES
                (l_id_protocol_task_array(r),
                 l_id_group_task_array(r),
                 l_descr_protocol_task_array(r),
                 l_task_type_array(r),
                 l_task_notes_array(r),
                 l_id_task_attach_array(r),
                 l_task_codif_array(r),
                 l_id_task_link_array(r));
    
        o_result_tbl := l_id_protocol_task_array.count;
        IF o_result_tbl > 0
        THEN
            g_cfg_done := 'TRUE';
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            o_result_tbl := 0;
            RETURN FALSE;
    END set_inst_protocol_task;
    FUNCTION set_protocol_criteria_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_protocol_criteria_search');
        INSERT INTO protocol_criteria
            (id_protocol_criteria,
             id_protocol,
             criteria_type,
             gender,
             min_age,
             max_age,
             min_weight,
             max_weight,
             id_weight_unit_measure,
             min_height,
             max_height,
             id_height_unit_measure,
             imc_min,
             imc_max,
             id_blood_pressure_unit_measure,
             min_blood_pressure_s,
             max_blood_pressure_s,
             min_blood_pressure_d,
             max_blood_pressure_d)
            SELECT seq_protocol_criteria.nextval,
                   def_data.id_protocol,
                   def_data.criteria_type,
                   def_data.gender,
                   def_data.min_age,
                   def_data.max_age,
                   def_data.min_weight,
                   def_data.max_weight,
                   def_data.id_weight_unit_measure,
                   def_data.min_height,
                   def_data.max_height,
                   def_data.id_height_unit_measure,
                   def_data.imc_min,
                   def_data.imc_max,
                   def_data.id_blood_pressure_unit_measure,
                   def_data.min_blood_pressure_s,
                   def_data.max_blood_pressure_s,
                   def_data.min_blood_pressure_d,
                   def_data.max_blood_pressure_d
              FROM (SELECT temp_data.id_protocol,
                           temp_data.criteria_type,
                           temp_data.gender,
                           temp_data.min_age,
                           temp_data.max_age,
                           temp_data.min_weight,
                           temp_data.max_weight,
                           temp_data.id_weight_unit_measure,
                           temp_data.min_height,
                           temp_data.max_height,
                           temp_data.id_height_unit_measure,
                           temp_data.imc_min,
                           temp_data.imc_max,
                           temp_data.id_blood_pressure_unit_measure,
                           temp_data.min_blood_pressure_s,
                           temp_data.max_blood_pressure_s,
                           temp_data.min_blood_pressure_d,
                           temp_data.max_blood_pressure_d,
                           row_number() over(PARTITION BY temp_data.id_protocol, temp_data.criteria_type
                           
                           ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT src_tbl.rowid l_row,
                                   nvl((SELECT ext_p.id_protocol
                                         FROM protocol ext_p
                                        INNER JOIN alert_default.protocol int_p
                                           ON (int_p.id_content = ext_p.id_content)
                                        WHERE ext_p.id_institution = i_institution
                                          AND int_p.id_protocol = src_tbl.id_protocol),
                                       0) id_protocol,
                                   src_tbl.criteria_type,
                                   src_tbl.gender,
                                   src_tbl.min_age,
                                   src_tbl.max_age,
                                   src_tbl.min_weight,
                                   src_tbl.max_weight,
                                   src_tbl.id_weight_unit_measure,
                                   src_tbl.min_height,
                                   src_tbl.max_height,
                                   src_tbl.id_height_unit_measure,
                                   src_tbl.imc_min,
                                   src_tbl.imc_max,
                                   src_tbl.id_blood_pressure_unit_measure,
                                   src_tbl.min_blood_pressure_s,
                                   src_tbl.max_blood_pressure_s,
                                   src_tbl.min_blood_pressure_d,
                                   src_tbl.max_blood_pressure_d,
                                   pmv.id_market,
                                   pmv.version
                            -- decode FKS to dest_vals
                              FROM protocol_criteria src_tbl
                             INNER JOIN alert_default.protocol_mrk_vrs pmv
                                ON (pmv.id_protocol = src_tbl.id_protocol)
                             WHERE pmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND pmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_protocol > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM protocol_criteria dest_tbl
                     WHERE dest_tbl.id_protocol = def_data.id_protocol
                       AND dest_tbl.criteria_type = def_data.criteria_type);
    
        o_result_tbl := SQL%ROWCOUNT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_protocol_criteria_search;
    FUNCTION set_inst_protocol_crit_link
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_protocol_criteria_def protocol_criteria_link.id_protocol_criteria%TYPE;
        l_id_link_other_criteria   protocol_criteria_link.id_link_other_criteria%TYPE;
        l_id_link_other_crit_type  protocol_criteria_link.id_link_other_criteria_type%TYPE;
        l_id_protocol              protocol.id_protocol%TYPE;
        l_protocol_content         protocol.id_content%TYPE;
        l_id_protocol_criteria     protocol_criteria.id_protocol_criteria%TYPE;
    
        l_criteria_type_def protocol_criteria.criteria_type%TYPE;
        l_criteria_type     protocol_criteria.criteria_type%TYPE;
    
        l_id_protocol_criteria_array   table_number := table_number();
        l_id_link_other_criteria_array table_number := table_number();
        l_id_link_other_cri_type_array table_number := table_number();
    
        l_index NUMBER := 1;
    
        l_id_analysis    analysis.id_analysis%TYPE := NULL;
        l_count_analysis NUMBER := 0;
    
        l_id_diagnosis    diagnosis.id_diagnosis%TYPE := NULL;
        l_count_diagnosis NUMBER := 0;
    
        l_id_img_exams    exam.id_exam%TYPE := NULL;
        l_count_img_exams NUMBER := 0;
    
        l_id_other_exams    exam.id_exam%TYPE := NULL;
        l_count_other_exams NUMBER := 0;
    
        l_id_icnp_diag    icnp_composition.id_composition%TYPE := NULL;
        l_count_icnp_diag NUMBER := 0;
    
        l_id_allergy    allergy.id_allergy%TYPE := NULL;
        l_count_allergy NUMBER := 0;
    
        l_tot NUMBER := 0;
    
        CURSOR c_protocol_criteria_link IS
            SELECT DISTINCT pcl.id_protocol_criteria,
                            pcl.id_link_other_criteria,
                            pcl.id_link_other_criteria_type,
                            p.id_content,
                            pc.criteria_type
              FROM alert_default.protocol_criteria_link pcl
              JOIN alert_default.protocol_criteria pc
                ON (pc.id_protocol_criteria = pcl.id_protocol_criteria)
              JOIN protocol_criteria_type pct
                ON (pct.id_protocol_criteria_type = pcl.id_link_other_criteria_type)
              JOIN alert_default.protocol p
                ON (p.id_protocol = pc.id_protocol)
              JOIN alert_default.protocol_mrk_vrs pmv
                ON (pmv.id_protocol = pc.id_protocol)
             WHERE pmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                      column_value
                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
               AND pmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                    column_value
                                     FROM TABLE(CAST(i_vers AS table_varchar)) p);
    
        CURSOR c_protocol_criteria(c_id_protocol IN protocol.id_protocol%TYPE) IS
            SELECT DISTINCT pc.id_protocol_criteria, pc.criteria_type
              FROM protocol_criteria pc
              JOIN protocol p1
                ON (p1.id_protocol = pc.id_protocol AND p1.id_protocol = c_id_protocol)
              JOIN alert_default.protocol p2
                ON (p2.id_content = p1.id_content)
              JOIN alert_default.protocol_criteria pc2
                ON (pc2.id_protocol = p2.id_protocol AND pc2.criteria_type = pc.criteria_type);
    
    BEGIN
        g_func_name := 'GET_INST_PROTOCOL_CRIT_LINK ';
    
        g_error := 'OPEN C_PROTOCOL_CRITERIA_LINK CURSOR';
        pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
        OPEN c_protocol_criteria_link;
        LOOP
            FETCH c_protocol_criteria_link
                INTO l_id_protocol_criteria_def,
                     l_id_link_other_criteria,
                     l_id_link_other_crit_type,
                     l_protocol_content,
                     l_criteria_type_def;
            EXIT WHEN c_protocol_criteria_link%NOTFOUND;
        
            IF l_protocol_content IS NOT NULL
            THEN
                g_error := 'GET ALERT PROTOCOL ID';
                pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                SELECT nvl((SELECT p.id_protocol
                             FROM protocol p
                            WHERE p.id_content = l_protocol_content
                              AND p.id_content IS NOT NULL
                              AND p.id_institution = i_institution
                              AND rownum = 1),
                           0)
                  INTO l_id_protocol
                  FROM dual;
            
                IF l_id_protocol != 0
                THEN
                    g_error := 'OPEN C_PROTOCOL_CRITERIA CURSOR';
                    pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                    OPEN c_protocol_criteria(l_id_protocol);
                    LOOP
                        FETCH c_protocol_criteria
                            INTO l_id_protocol_criteria, l_criteria_type;
                        EXIT WHEN c_protocol_criteria%NOTFOUND;
                    
                        IF l_id_protocol_criteria IS NOT NULL
                           AND l_criteria_type_def = l_criteria_type
                        THEN
                            --> Allergy
                            IF l_id_link_other_crit_type = 1
                            THEN
                                SELECT nvl((SELECT a.id_allergy
                                             FROM allergy a
                                             JOIN allergy_inst_soft ais
                                               ON (ais.id_allergy = a.id_allergy AND ais.id_institution = i_institution)
                                           --Não valida por sw                 
                                            WHERE a.id_allergy = l_id_link_other_criteria
                                              AND a.flg_available = g_flg_available
                                              AND rownum = 1),
                                           0)
                                  INTO l_id_allergy
                                  FROM dual;
                            
                                IF l_id_allergy != 0
                                THEN
                                    g_error := 'COUNT CRITERIA_LINK by ALLERGY';
                                    pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                                    SELECT COUNT(pcl.id_protocol_criteria_link)
                                      INTO l_count_allergy
                                      FROM protocol_criteria_link pcl
                                     WHERE pcl.id_protocol_criteria = l_id_protocol_criteria
                                       AND pcl.id_link_other_criteria_type = l_id_link_other_crit_type
                                       AND pcl.id_link_other_criteria = l_id_allergy;
                                
                                    IF l_count_allergy = 0
                                    THEN
                                        l_id_protocol_criteria_array.extend;
                                        l_id_link_other_criteria_array.extend;
                                        l_id_link_other_cri_type_array.extend;
                                    
                                        l_id_protocol_criteria_array(l_index) := l_id_protocol_criteria;
                                        l_id_link_other_criteria_array(l_index) := l_id_allergy;
                                        l_id_link_other_cri_type_array(l_index) := l_id_link_other_crit_type;
                                    
                                        l_index := l_index + 1;
                                    END IF;
                                
                                END IF;
                            END IF;
                            --> Analysis
                            IF l_id_link_other_crit_type = 2
                            THEN
                                g_error := 'GET ALERT ID_ANALYSIS';
                                pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                                SELECT nvl((SELECT a.id_analysis
                                             FROM analysis a
                                             JOIN analysis_instit_soft ais
                                               ON (ais.id_analysis = a.id_analysis AND
                                                  ais.id_institution = i_institution AND
                                                  ais.flg_available = g_flg_available)
                                           -->Não valida por sw
                                             JOIN analysis_param ap
                                               ON (ap.id_analysis = a.id_analysis AND
                                                  ap.flg_available = g_flg_available)
                                           -->Não valida por sw                  
                                            WHERE a.id_content =
                                                  (SELECT a2.id_content
                                                     FROM alert_default.analysis a2
                                                    WHERE a2.id_analysis = l_id_link_other_criteria
                                                      AND a2.flg_available = g_flg_available)
                                              AND a.id_content IS NOT NULL
                                              AND a.flg_available = g_flg_available
                                              AND rownum = 1),
                                           0)
                                  INTO l_id_analysis
                                  FROM dual;
                            
                                IF l_id_analysis != 0
                                THEN
                                    g_error := 'COUNT CRITERIA_LINK by ANALYSIS';
                                    pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                                    SELECT COUNT(pcl.id_protocol_criteria_link)
                                      INTO l_count_analysis
                                      FROM protocol_criteria_link pcl
                                     WHERE pcl.id_protocol_criteria = l_id_protocol_criteria
                                       AND pcl.id_link_other_criteria_type = l_id_link_other_crit_type
                                       AND pcl.id_link_other_criteria = l_id_analysis;
                                
                                    IF l_count_analysis = 0
                                    THEN
                                        l_id_protocol_criteria_array.extend;
                                        l_id_link_other_criteria_array.extend;
                                        l_id_link_other_cri_type_array.extend;
                                    
                                        l_id_protocol_criteria_array(l_index) := l_id_protocol_criteria;
                                        l_id_link_other_criteria_array(l_index) := l_id_analysis;
                                        l_id_link_other_cri_type_array(l_index) := l_id_link_other_crit_type;
                                    
                                        l_index := l_index + 1;
                                    END IF;
                                END IF;
                            END IF;
                            --> Diagnosis
                            IF l_id_link_other_crit_type = 3
                            THEN
                                SELECT nvl((SELECT d.id_diagnosis
                                             FROM diagnosis d
                                             JOIN diagnosis_dep_clin_serv ddcs
                                               ON (ddcs.id_diagnosis = d.id_diagnosis AND
                                                  ddcs.id_institution = i_institution AND
                                                  ddcs.flg_type = pk_diagnosis.g_diag_pesq)
                                           --Não valida por sw                 
                                            WHERE d.id_diagnosis = l_id_link_other_criteria
                                              AND d.flg_available = g_flg_available
                                              AND rownum = 1),
                                           0)
                                  INTO l_id_diagnosis
                                  FROM dual;
                            
                                IF l_id_diagnosis != 0
                                THEN
                                    g_error := 'COUNT CRITERIA_LINK by DIAGNOSIS';
                                    pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                                    SELECT COUNT(pcl.id_protocol_criteria_link)
                                      INTO l_count_diagnosis
                                      FROM protocol_criteria_link pcl
                                     WHERE pcl.id_protocol_criteria = l_id_protocol_criteria
                                       AND pcl.id_link_other_criteria_type = l_id_link_other_crit_type
                                       AND pcl.id_link_other_criteria = l_id_diagnosis;
                                
                                    IF l_count_diagnosis = 0
                                    THEN
                                        l_id_protocol_criteria_array.extend;
                                        l_id_link_other_criteria_array.extend;
                                        l_id_link_other_cri_type_array.extend;
                                    
                                        l_id_protocol_criteria_array(l_index) := l_id_protocol_criteria;
                                        l_id_link_other_criteria_array(l_index) := l_id_diagnosis;
                                        l_id_link_other_cri_type_array(l_index) := l_id_link_other_crit_type;
                                    
                                        l_index := l_index + 1;
                                    END IF;
                                
                                END IF;
                            END IF;
                            --> Image Exams
                            IF l_id_link_other_crit_type = 4
                            THEN
                                g_error := 'GET ALERT ID_IMG_EXAMS';
                                pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                                SELECT nvl((SELECT e.id_exam
                                             FROM exam e
                                             JOIN exam_dep_clin_serv edcs
                                               ON (edcs.id_exam = e.id_exam AND edcs.id_institution = i_institution AND
                                                  edcs.flg_type = pk_exam_constant.g_exam_can_req)
                                           --Não valida por sw
                                            WHERE e.id_content =
                                                  (SELECT e2.id_content
                                                     FROM alert_default.exam e2
                                                    WHERE e2.id_exam = l_id_link_other_criteria
                                                      AND e2.flg_available = g_flg_available)
                                              AND e.id_content IS NOT NULL
                                              AND e.flg_available = g_flg_available
                                              AND e.flg_type = pk_exam_constant.g_type_img
                                              AND rownum = 1),
                                           0)
                                  INTO l_id_img_exams
                                  FROM dual;
                            
                                IF l_id_img_exams != 0
                                THEN
                                    g_error := 'COUNT CRITERIA_LINK by IMG_EXAMS';
                                    pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                                    SELECT COUNT(pcl.id_protocol_criteria_link)
                                      INTO l_count_img_exams
                                      FROM protocol_criteria_link pcl
                                     WHERE pcl.id_protocol_criteria = l_id_protocol_criteria
                                       AND pcl.id_link_other_criteria_type = l_id_link_other_crit_type
                                       AND pcl.id_link_other_criteria = l_id_img_exams;
                                
                                    IF l_count_img_exams = 0
                                    THEN
                                        l_id_protocol_criteria_array.extend;
                                        l_id_link_other_criteria_array.extend;
                                        l_id_link_other_cri_type_array.extend;
                                    
                                        l_id_protocol_criteria_array(l_index) := l_id_protocol_criteria;
                                        l_id_link_other_criteria_array(l_index) := l_id_img_exams;
                                        l_id_link_other_cri_type_array(l_index) := l_id_link_other_crit_type;
                                    
                                        l_index := l_index + 1;
                                    END IF;
                                END IF;
                            END IF;
                            --> Other Exams
                            IF l_id_link_other_crit_type = 6
                            THEN
                                g_error := 'GET ALERT ID_OTHER_EXAMS';
                                pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                                SELECT nvl((SELECT e.id_exam
                                             FROM exam e
                                             JOIN exam_dep_clin_serv edcs
                                               ON (edcs.id_exam = e.id_exam AND edcs.id_institution = i_institution AND
                                                  edcs.flg_type = pk_exam_constant.g_exam_can_req)
                                           --Não valida por sw
                                            WHERE e.id_content =
                                                  (SELECT e2.id_content
                                                     FROM alert_default.exam e2
                                                    WHERE e2.id_exam = l_id_link_other_criteria
                                                      AND e2.flg_available = g_flg_available)
                                              AND e.id_content IS NOT NULL
                                              AND e.flg_available = g_flg_available
                                              AND e.flg_type = pk_exam_constant.g_type_exm
                                              AND rownum = 1),
                                           0)
                                  INTO l_id_other_exams
                                  FROM dual;
                            
                                IF l_id_other_exams != 0
                                THEN
                                    g_error := 'COUNT CRITERIA_LINK by OTHER_EXAMS';
                                    pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                                    SELECT COUNT(pcl.id_protocol_criteria_link)
                                      INTO l_count_other_exams
                                      FROM protocol_criteria_link pcl
                                     WHERE pcl.id_protocol_criteria = l_id_protocol_criteria
                                       AND pcl.id_link_other_criteria_type = l_id_link_other_crit_type
                                       AND pcl.id_link_other_criteria = l_id_other_exams;
                                
                                    IF l_count_other_exams = 0
                                    THEN
                                        l_id_protocol_criteria_array.extend;
                                        l_id_link_other_criteria_array.extend;
                                        l_id_link_other_cri_type_array.extend;
                                    
                                        l_id_protocol_criteria_array(l_index) := l_id_protocol_criteria;
                                        l_id_link_other_criteria_array(l_index) := l_id_other_exams;
                                        l_id_link_other_cri_type_array(l_index) := l_id_link_other_crit_type;
                                    
                                        l_index := l_index + 1;
                                    END IF;
                                END IF;
                            END IF;
                            --> ICNP Diagnosis
                            IF l_id_link_other_crit_type = 7
                            THEN
                                g_error := 'GET ALERT ID_ICNP_DIAGNOSIS';
                                pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                            
                                SELECT nvl((SELECT /*DISTINCT*/
                                            ic.id_composition
                                             FROM icnp_composition ic
                                             JOIN icnp_predefined_action ipa
                                               ON (ipa.id_composition_parent = ic.id_composition AND
                                                  ipa.id_institution = i_institution AND
                                                  ipa.flg_available = g_flg_available)
                                            WHERE ic.id_content =
                                                 --Não valida por sw
                                                  (SELECT ic2.id_content
                                                     FROM alert_default.icnp_composition ic2
                                                     JOIN alert_default.icnp_predefined_action ipa2
                                                       ON (ipa2.id_composition_parent = ic2.id_composition AND
                                                          ipa2.flg_available = g_flg_available)
                                                    WHERE ic2.id_composition = l_id_link_other_criteria
                                                      AND ic2.flg_available = g_flg_available
                                                      AND ipa2.version IN
                                                          (SELECT /*+ dynamic_sampling(p 2)*/
                                                            column_value
                                                             FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                                      AND ipa2.id_market IN
                                                          (SELECT /*+ dynamic_sampling(p 2)*/
                                                            column_value
                                                             FROM TABLE(CAST(i_mkt AS table_number)) p))
                                              AND ic.id_content IS NOT NULL
                                              AND ic.flg_available = g_flg_available
                                              AND ic.flg_type = 'D'
                                              AND rownum = 1),
                                           0)
                                  INTO l_id_icnp_diag
                                  FROM dual;
                            
                                IF l_id_icnp_diag != 0
                                THEN
                                    g_error := 'COUNT CRITERIA_LINK by ICNP_DIAGNOSIS';
                                    pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                                    SELECT COUNT(pcl.id_protocol_criteria_link)
                                      INTO l_count_icnp_diag
                                      FROM protocol_criteria_link pcl
                                     WHERE pcl.id_protocol_criteria = l_id_protocol_criteria
                                       AND pcl.id_link_other_criteria_type = l_id_link_other_crit_type
                                       AND pcl.id_link_other_criteria = l_id_icnp_diag;
                                
                                    IF l_count_icnp_diag = 0
                                    THEN
                                        l_id_protocol_criteria_array.extend;
                                        l_id_link_other_criteria_array.extend;
                                        l_id_link_other_cri_type_array.extend;
                                    
                                        l_id_protocol_criteria_array(l_index) := l_id_protocol_criteria;
                                        l_id_link_other_criteria_array(l_index) := l_id_icnp_diag;
                                        l_id_link_other_cri_type_array(l_index) := l_id_link_other_crit_type;
                                    
                                        l_index := l_index + 1;
                                    END IF;
                                END IF;
                            END IF;
                        END IF;
                    END LOOP;
                    g_error := 'CLOSE C_PROTOCOL_CRITERIA CURSOR';
                    pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
                    CLOSE c_protocol_criteria;
                END IF;
            END IF;
            l_tot := l_tot + 1;
        END LOOP;
        g_error := 'CLOSE C_PROTOCOL_CRITERIA_LINK CURSOR';
        pk_alertlog.log_debug('PK_BACKOFFICE_DEFAULT.' || g_func_name || g_error);
        CLOSE c_protocol_criteria_link;
    
        FORALL p IN 1 .. l_id_protocol_criteria_array.count
            INSERT INTO protocol_criteria_link
                (id_protocol_criteria_link, id_protocol_criteria, id_link_other_criteria_type, id_link_other_criteria)
            VALUES
                (seq_protocol_criteria_link.nextval,
                 l_id_protocol_criteria_array(p),
                 l_id_link_other_cri_type_array(p),
                 l_id_link_other_criteria_array(p));
    
        o_result_tbl := l_tot;
        IF o_result_tbl > 0
        THEN
            g_cfg_done := 'TRUE';
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            o_result_tbl := 0;
            RETURN FALSE;
    END set_inst_protocol_crit_link;
    FUNCTION set_protocol_adv_input_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_var_t VARCHAR2(1) := pk_protocol.g_adv_input_type_tasks;
        l_var_c VARCHAR2(1) := pk_protocol.g_adv_input_type_criterias;
    
    BEGIN
        g_func_name := upper('set_protocol_adv_input_search');
        INSERT INTO protocol_adv_input_value
            (id_protocol_adv_input_value,
             id_adv_input_link,
             flg_type,
             id_advanced_input,
             id_advanced_input_field,
             id_advanced_input_field_det,
             value_type,
             nvalue,
             dvalue,
             vvalue,
             value_desc,
             criteria_value_type)
            SELECT seq_protocol_adv_input_value.nextval,
                   def_data.id_adv_input_link,
                   def_data.flg_type,
                   def_data.id_advanced_input,
                   def_data.id_advanced_input_field,
                   def_data.id_advanced_input_field_det,
                   def_data.value_type,
                   def_data.nvalue,
                   def_data.dvalue,
                   def_data.vvalue,
                   def_data.value_desc,
                   def_data.criteria_value_type
              FROM (SELECT temp_data.id_adv_input_link,
                           temp_data.flg_type,
                           temp_data.id_advanced_input,
                           temp_data.id_advanced_input_field,
                           temp_data.id_advanced_input_field_det,
                           temp_data.value_type,
                           temp_data.nvalue,
                           temp_data.dvalue,
                           temp_data.vvalue,
                           temp_data.value_desc,
                           temp_data.criteria_value_type,
                           row_number() over(PARTITION BY temp_data.id_adv_input_link, temp_data.flg_type, temp_data.id_advanced_input, temp_data.id_advanced_input_field, temp_data.id_advanced_input_field_det
                           
                           ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT src_tbl.rowid l_row,
                                   nvl((SELECT ext_pc.id_protocol_criteria
                                         FROM protocol_criteria ext_pc
                                        INNER JOIN protocol ext_p
                                           ON (ext_p.id_protocol = ext_pc.id_protocol AND
                                              ext_p.id_institution = i_institution)
                                        INNER JOIN alert_default.protocol int_p
                                           ON (int_p.id_content = ext_p.id_content)
                                        WHERE int_p.id_protocol = pc.id_protocol),
                                       0) id_adv_input_link,
                                   src_tbl.flg_type,
                                   src_tbl.id_advanced_input,
                                   src_tbl.id_advanced_input_field,
                                   src_tbl.id_advanced_input_field_det,
                                   src_tbl.value_type,
                                   src_tbl.nvalue,
                                   src_tbl.dvalue,
                                   src_tbl.vvalue,
                                   src_tbl.value_desc,
                                   src_tbl.criteria_value_type,
                                   pmv.id_market,
                                   pmv.version
                            -- decode FKS to dest_vals
                              FROM alert_default.protocol_adv_input_value src_tbl
                             INNER JOIN alert_default.protocol_criteria pc
                                ON (pc.id_protocol_criteria = src_tbl.id_adv_input_link)
                             INNER JOIN alert_default.protocol_mrk_vrs pmv
                                ON (pmv.id_protocol = pc.id_protocol)
                             WHERE pmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND pmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND src_tbl.flg_type = l_var_c
                            UNION
                            SELECT src_tbl.rowid l_row,
                                   nvl((SELECT ext_pt.id_protocol_task
                                         FROM protocol_task ext_pt
                                        INNER JOIN protocol_element ext_pe
                                           ON (ext_pe.id_element = ext_pt.id_group_task AND ext_pe.element_type = l_var_t AND
                                              ext_pe.flg_available = g_flg_available)
                                        INNER JOIN protocol ext_p
                                           ON (ext_p.id_protocol = ext_pe.id_protocol AND
                                              ext_p.id_institution = i_institution)
                                        INNER JOIN alert_default.protocol int_p
                                           ON (int_p.id_content = ext_p.id_content)
                                        WHERE int_p.id_protocol = pe.id_protocol),
                                       0) id_adv_input_link,
                                   src_tbl.flg_type,
                                   src_tbl.id_advanced_input,
                                   src_tbl.id_advanced_input_field,
                                   src_tbl.id_advanced_input_field_det,
                                   src_tbl.value_type,
                                   src_tbl.nvalue,
                                   src_tbl.dvalue,
                                   src_tbl.vvalue,
                                   src_tbl.value_desc,
                                   src_tbl.criteria_value_type,
                                   pmv.id_market,
                                   pmv.version
                              FROM alert_default.protocol_adv_input_value src_tbl
                              JOIN alert_default.protocol_task pt
                                ON (pt.id_protocol_task = src_tbl.id_adv_input_link)
                              JOIN alert_default.protocol_element pe
                                ON (pe.id_element = pt.id_group_task AND pe.element_type = l_var_t AND
                                   pe.flg_available = g_flg_available)
                              JOIN alert_default.protocol_mrk_vrs pmv
                                ON (pmv.id_protocol = pe.id_protocol)
                             WHERE src_tbl.flg_type = l_var_t
                               AND pmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND pmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND def_data.id_adv_input_link > 0
               AND NOT EXISTS (SELECT 0
                      FROM protocol_adv_input_value dest_tbl
                     WHERE dest_tbl.id_adv_input_link = def_data.id_adv_input_link
                       AND dest_tbl.flg_type = def_data.flg_type
                       AND dest_tbl.id_advanced_input = def_data.id_advanced_input
                       AND dest_tbl.id_advanced_input_field = def_data.id_advanced_input_field
                       AND (dest_tbl.id_advanced_input_field_det = def_data.id_advanced_input_field_det OR
                           dest_tbl.id_advanced_input_field_det IS NULL));
    
        o_result_tbl := SQL%ROWCOUNT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_protocol_adv_input_search;
    FUNCTION set_inst_prot_ctx_auth_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_set_inst_prot_context_auth_search');
        INSERT INTO protocol_context_author
            (id_protocol_context_author, id_protocol, first_name, last_name, title)
            SELECT seq_protocol_context_author.nextval,
                   def_data.id_protocol,
                   def_data.first_name,
                   def_data.last_name,
                   def_data.title
              FROM (SELECT temp_data.id_protocol,
                           temp_data.first_name,
                           temp_data.last_name,
                           temp_data.title,
                           row_number() over(PARTITION BY temp_data.id_protocol, temp_data.first_name, temp_data.last_name, temp_data.title
                           
                           ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT ext_p.id_protocol
                                         FROM protocol ext_p
                                        INNER JOIN alert_default.protocol int_p
                                           ON (int_p.id_content = ext_p.id_content)
                                        WHERE ext_p.flg_status = g_finished
                                          AND int_p.id_protocol = src_tbl.id_protocol
                                          AND ext_p.id_institution = i_institution),
                                       0) id_protocol,
                                   src_tbl.first_name,
                                   src_tbl.last_name,
                                   src_tbl.title,
                                   pmv.id_market,
                                   pmv.version
                            -- decode FKS to dest_vals
                              FROM alert_default.protocol_context_author src_tbl
                             INNER JOIN alert_default.protocol_mrk_vrs pmv
                                ON (pmv.id_protocol = src_tbl.id_protocol)
                             WHERE pmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND pmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_protocol > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM protocol_context_author dest_tbl
                     WHERE dest_tbl.id_protocol = def_data.id_protocol
                       AND dest_tbl.first_name = def_data.first_name
                       AND dest_tbl.last_name = def_data.last_name
                       AND dest_tbl.title = def_data.title);
    
        o_result_tbl := SQL%ROWCOUNT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_inst_prot_ctx_auth_search;
    FUNCTION set_protocol_ctx_img_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_protocol_ctx_img_search');
        INSERT INTO protocol_context_image
            (id_protocol_context_image, id_protocol, file_name, img_desc, dt_img, img, img_thumbnail, flg_status)
            SELECT seq_protocol_context_image.nextval,
                   def_data.id_protocol,
                   def_data.file_name,
                   def_data.img_desc,
                   def_data.dt_img,
                   def_data.img,
                   def_data.img_thumbnail,
                   def_data.flg_status
              FROM (SELECT temp_data.id_protocol,
                           temp_data.file_name,
                           temp_data.img_desc,
                           temp_data.dt_img,
                           temp_data.img,
                           temp_data.img_thumbnail,
                           temp_data.flg_status,
                           row_number() over(PARTITION BY temp_data.id_protocol, temp_data.file_name, temp_data.img_desc, temp_data.dt_img
                           
                           ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT ext_p.id_protocol
                                         FROM protocol ext_p
                                        INNER JOIN alert_default.protocol int_p
                                           ON (int_p.id_content = ext_p.id_content)
                                        WHERE ext_p.flg_status = g_finished
                                          AND int_p.id_protocol = src_tbl.id_protocol
                                          AND ext_p.id_institution = i_institution),
                                       0) id_protocol,
                                   src_tbl.file_name,
                                   src_tbl.img_desc,
                                   src_tbl.dt_img,
                                   src_tbl.img,
                                   src_tbl.img_thumbnail,
                                   src_tbl.flg_status,
                                   pmv.id_market,
                                   pmv.version
                            -- decode FKS to dest_vals
                              FROM alert_default.protocol_context_image src_tbl
                             INNER JOIN alert_default.protocol_mrk_vrs pmv
                                ON (pmv.id_protocol = src_tbl.id_protocol)
                             WHERE pmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND pmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND def_data.id_protocol > 0
               AND NOT EXISTS (SELECT 0
                      FROM protocol_context_image dest_tbl
                     WHERE dest_tbl.id_protocol = def_data.id_protocol
                       AND dest_tbl.file_name = def_data.file_name
                       AND dest_tbl.img_desc = def_data.img_desc
                       AND dest_tbl.dt_img = def_data.dt_img
                       AND dbms_lob.compare(dest_tbl.img, def_data.img) > 0
                       AND dbms_lob.compare(dest_tbl.img_thumbnail, def_data.img_thumbnail) > 0
                       AND dest_tbl.flg_status = def_data.flg_status);
    
        o_result_tbl := SQL%ROWCOUNT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_protocol_ctx_img_search;
    FUNCTION set_protocol_connector_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_protocol_connector_search');
        INSERT INTO protocol_connector
            (id_protocol_connector, desc_protocol_connector, flg_desc_protocol_connector, flg_available)
            SELECT def_data.id_protocol_connector,
                   def_data.desc_protocol_connector,
                   def_data.flg_desc_protocol_connector,
                   def_data.flg_available
              FROM (SELECT temp_data.id_protocol_connector,
                           temp_data.desc_protocol_connector,
                           temp_data.flg_desc_protocol_connector,
                           temp_data.flg_available,
                           row_number() over(PARTITION BY temp_data.id_protocol_connector ORDER BY temp_data.l_row) records_count
                      FROM (SELECT src_tbl.rowid l_row,
                                   id_protocol_connector,
                                   desc_protocol_connector,
                                   flg_desc_protocol_connector,
                                   flg_available
                            -- decode FKS to dest_vals
                              FROM alert_default.protocol_connector src_tbl
                             WHERE src_tbl.flg_available = g_flg_available) temp_data) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM protocol_connector dest_tbl
                     WHERE dest_tbl.id_protocol_connector = def_data.id_protocol_connector
                       AND flg_available = g_flg_available);
        o_result_tbl := SQL%ROWCOUNT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_protocol_connector_search;
    FUNCTION set_protocol_relation_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_protocol_relation_search');
        INSERT INTO protocol_relation
            (id_protocol_relation,
             id_protocol,
             id_protocol_element_parent,
             id_protocol_connector,
             id_protocol_element,
             desc_relation,
             flg_available)
            SELECT seq_protocol_relation.nextval,
                   def_data.id_protocol,
                   def_data.id_protocol_element_parent,
                   def_data.id_protocol_connector,
                   def_data.id_protocol_element,
                   def_data.desc_relation,
                   def_data.flg_available
              FROM (SELECT norm_data.id_protocol,
                           norm_data.id_protocol_element_parent,
                           norm_data.id_protocol_connector,
                           norm_data.id_protocol_element,
                           norm_data.desc_relation,
                           norm_data.flg_available,
                           row_number() over(PARTITION BY norm_data.id_protocol, norm_data.id_protocol_element_parent, norm_data.id_protocol_connector, norm_data.id_protocol_element
                           
                           ORDER BY norm_data.id_market DESC, decode(norm_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT temp_data.id_protocol,
                                   nvl((SELECT ext_pe1.id_protocol_element
                                         FROM protocol_element ext_pe1
                                        WHERE ext_pe1.id_protocol = temp_data.id_protocol
                                          AND ext_pe1.id_element = temp_data.parent_element_type
                                          AND ext_pe1.element_type = temp_data.parent_element_id
                                          AND ext_pe1.flg_available = g_flg_available),
                                       0) id_protocol_element_parent,
                                   nvl((SELECT ext_pc.id_protocol_connector
                                         FROM protocol_connector ext_pc
                                        WHERE ext_pc.id_protocol_connector = temp_data.id_protocol_connector
                                          AND ext_pc.flg_available = g_flg_available),
                                       0) id_protocol_connector,
                                   nvl((SELECT ext_pe1.id_protocol_element
                                         FROM protocol_element ext_pe1
                                        WHERE ext_pe1.id_protocol = temp_data.id_protocol
                                          AND ext_pe1.id_element = temp_data.child_element_type
                                          AND ext_pe1.element_type = temp_data.child_element_id
                                          AND ext_pe1.flg_available = g_flg_available),
                                       0) id_protocol_element,
                                   temp_data.desc_relation,
                                   temp_data.flg_available,
                                   temp_data.id_market,
                                   temp_data.version
                              FROM (SELECT nvl((SELECT ext_p.id_protocol
                                                 FROM protocol ext_p
                                                INNER JOIN alert_default.protocol int_p
                                                   ON (int_p.id_content = ext_p.id_content)
                                                WHERE ext_p.id_institution = i_institution
                                                  AND int_p.id_protocol = src_tbl.id_protocol),
                                               0) id_protocol,
                                           src_tbl.id_protocol_element_parent,
                                           src_tbl.id_protocol_connector,
                                           src_tbl.id_protocol_element,
                                           pe_child.element_type child_element_type,
                                           pe_child.id_element child_element_id,
                                           pe_parent.id_element parent_element_id,
                                           pe_parent.element_type parent_element_type,
                                           src_tbl.desc_relation,
                                           src_tbl.flg_available,
                                           pmv.id_market,
                                           pmv.version
                                    -- decode FKS to dest_vals
                                      FROM alert_default.protocol_relation src_tbl
                                     INNER JOIN alert_default.protocol_element pe_parent
                                        ON (pe_parent.id_protocol_element = src_tbl.id_protocol_element_parent AND
                                           pe_parent.flg_available = g_flg_available)
                                     INNER JOIN alert_default.protocol_element pe_child
                                        ON (pe_child.id_protocol_element = src_tbl.id_protocol_element AND
                                           pe_child.flg_available = g_flg_available)
                                     INNER JOIN alert_default.protocol_connector pc
                                        ON (pc.id_protocol_connector = src_tbl.id_protocol_connector AND
                                           pc.flg_available = g_flg_available)
                                     INNER JOIN alert_default.protocol_mrk_vrs pmv
                                        ON (pmv.id_protocol = src_tbl.id_protocol)
                                     WHERE pmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                              column_value
                                                               FROM TABLE(CAST(i_mkt AS table_number)) p)
                                          
                                       AND pmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                            column_value
                                                             FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                       AND src_tbl.flg_available = g_flg_available) temp_data
                             WHERE temp_data.id_protocol > 0) norm_data
                     WHERE norm_data.id_protocol_element_parent > 0
                       AND norm_data.id_protocol_connector > 0
                       AND norm_data.id_protocol_element > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM protocol_relation dest_tbl
                     WHERE dest_tbl.id_protocol = def_data.id_protocol
                       AND dest_tbl.id_protocol_element_parent = def_data.id_protocol_element_parent
                       AND dest_tbl.id_protocol_connector = def_data.id_protocol_connector
                       AND dest_tbl.id_protocol_element = def_data.id_protocol_element
                       AND dest_tbl.flg_available = g_flg_available);
    
        o_result_tbl := SQL%ROWCOUNT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_protocol_relation_search;
    FUNCTION set_protocol_frequent_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_protocol_frequent_search');
        INSERT INTO protocol_frequent
            (id_protocol_frequent, id_protocol, id_institution, id_software, rank)
            SELECT seq_protocol_frequent.nextval,
                   def_data.id_protocol,
                   def_data.id_institution,
                   def_data.id_software,
                   def_data.rank
              FROM (SELECT temp_data.id_protocol,
                           i_institution id_institution,
                           i_software(1) id_software,
                           temp_data.rank,
                           row_number() over(PARTITION BY temp_data.id_protocol
                           
                           ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT ext_p.id_protocol
                                         FROM protocol ext_p
                                        INNER JOIN alert_default.protocol int_p
                                           ON (int_p.id_content = ext_p.id_content)
                                        WHERE ext_p.id_institution = i_institution
                                          AND int_p.id_protocol = src_tbl.id_protocol),
                                       0) id_protocol,
                                   
                                   src_tbl.rank,
                                   src_tbl.id_software,
                                   pmv.id_market,
                                   pmv.version
                            -- decode FKS to dest_vals
                              FROM alert_default.protocol_frequent src_tbl
                             INNER JOIN alert_default.protocol_mrk_vrs pmv
                                ON (pmv.id_protocol = src_tbl.id_protocol)
                             WHERE src_tbl.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND pmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND pmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_protocol > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM protocol_frequent dest_tbl
                     WHERE dest_tbl.id_protocol = def_data.id_protocol
                       AND dest_tbl.id_software = def_data.id_software
                       AND dest_tbl.id_institution = def_data.id_institution);
        o_result_tbl := SQL%ROWCOUNT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_protocol_frequent_search;
    -- frequent loader method

    -- global vars
    PROCEDURE reset_cfg_done IS
    BEGIN
        g_cfg_done := 'FALSE';
    END reset_cfg_done;

    FUNCTION get_cfg_done RETURN VARCHAR2 IS
    BEGIN
        RETURN g_cfg_done;
    END get_cfg_done;
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_finished         := 'F';
    g_temporary        := 'T';
    g_element_question := 'Q';
    g_element_protocol := 'P';

    g_array_size  := 100;
    g_array_size1 := 10000;
    g_cfg_done    := 'FALSE';
END pk_protocol_prm;
/
