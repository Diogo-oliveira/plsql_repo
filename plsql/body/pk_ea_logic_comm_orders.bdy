/*-- Last Change Revision: $Rev: 2027022 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:45 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_ea_logic_comm_orders IS

    -- Purpose : Communication orders easy access database package  

    --=========================== Error codes =====================
    --HELP: error_number is a negative integer in the range -20000..-20999 and message is a character string up to 2048 bytes long
    --References: https://docs.oracle.com/cd/B19306_01/appdev.102/b14261/errors.htm    
    er_argument_null CONSTANT NUMBER := -20101; --Argument null exception

    -- logging variables
    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);
    g_error         VARCHAR2(4000);

    -- debug mode enabled/disabled
    g_debug BOOLEAN;

    --Get concept_path with the format:
    --

    /**
    * Get the concept path based on its hierarchy
    * Get concept_path with the format:
    * <concept_term_uid1> > <concept_term_uid2> > <concept_term_uid3> > ...
    *
    * @param i_lang                   Professional preferred language    
    * @param i_id_concept_version     Concept version ID
    * @param i_id_inst_owner          Concept version institution owner
    * @param i_id_concept_type        Concept type ID
    * @param i_id_concept_type        Task type identifier
    *
    * @return                         The concept path description
    *
    * @author                         Tiago Silva    (Updated by Humberto Cardoso)
    * @version                        2.6.4          (Updated in 2.8.0.0)        
    * @since                          29/Apr/2014    (Updated in 2019/09/02)   
    */
    FUNCTION get_concept_path_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_id_concept_version IN concept_version.id_concept_version%TYPE,
        i_id_inst_owner      IN concept_version.id_inst_owner%TYPE,
        i_id_concept_type    IN concept_type.id_concept_type%TYPE,
        i_id_task_type       IN task_type.id_task_type%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT t_low_char := 'GET_CONCEPT_PATH_DESC';
    
        l_ret t_big_byte;
        l_sep t_low_char;
    
        CURSOR c_concept_parent IS
            SELECT d.concept_desc,
                   d.id_inst_owner,
                   d.id_concept_version,
                   d.id_cv_parent,
                   d.id_cv_inst_owner_parent,
                   LEVEL
              FROM (SELECT cver.id_inst_owner,
                           cver.id_concept_version,
                           pk_coding_terminology.get_parent_conc_vers(i_concept            => cver.id_concept,
                                                                      i_concept_inst_owner => cver.id_concept_inst_owner,
                                                                      i_terminology_ver    => cver.id_terminology_version,
                                                                      i_concept_type       => i_id_concept_type) id_cv_parent,
                           pk_coding_terminology.get_parent_inst_owner(i_concept            => cver.id_concept,
                                                                       i_concept_inst_owner => cver.id_concept_inst_owner,
                                                                       i_terminology_ver    => cver.id_terminology_version,
                                                                       i_concept_type       => i_id_concept_type) id_cv_inst_owner_parent,
                           pk_translation.get_translation(i_lang, cttt.code_concept_term) AS concept_desc
                      FROM concept_version cver
                      JOIN concept_term ct
                        ON ct.id_concept_vers_start = cver.id_concept_version
                       AND ct.id_concept_vers_end = cver.id_concept_version
                       AND ct.id_cncpt_vrs_inst_owner = cver.id_inst_owner
                      JOIN concept_term_task_type cttt
                        ON cttt.id_concept_term = ct.id_concept_term
                       AND cttt.id_cncpt_trm_inst_owner = ct.id_inst_owner
                       AND cttt.id_task_type = i_id_task_type) d
             WHERE LEVEL <> 1
            CONNECT BY PRIOR d.id_cv_parent = d.id_concept_version
                   AND PRIOR d.id_cv_inst_owner_parent = d.id_inst_owner
             START WITH d.id_concept_version = i_id_concept_version
                    AND d.id_inst_owner = i_id_inst_owner
             ORDER BY LEVEL DESC;
    BEGIN
        g_error := 'loop cursor';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
    
        FOR r_concept IN c_concept_parent
        LOOP
        
            l_ret := l_ret || l_sep || r_concept.concept_desc;
        
            l_sep := ' > ';
        END LOOP;
    
        RETURN l_ret;
    END get_concept_path_desc;

    /**
    * Load concept types ids for communication orders
    *
    * @param i_ids_task_types         List of task types identifiers to filter. If null, is not filtred
    * @param i_ids_concept_types      List of concept types identifiers to filter. If null, is not filtred
    * @param o_ids_task_types         List of all task types identifiers that are compatible with the filters.
    * @param o_ids_concept_types      List of all concept types identifiers that are compatible with the filters.
    *
    * @author                         Humberto Cardoso
    * @version                        2.8.0.0
    * @since                          2019/09/02
    */
    PROCEDURE load_concept_types_task_types
    (
        i_ids_task_types    IN table_number DEFAULT NULL,
        i_ids_concept_types IN table_number DEFAULT NULL,
        o_ids_task_types    OUT NOCOPY table_number,
        o_ids_concept_types OUT NOCOPY table_number
    ) IS
    
        -- Private variables
        l_func_name CONSTANT t_low_char := 'GET_CONCEPT_TYPE_LIST_IDS';
        l_error             t_error_out;
        l_has_task_types    NUMBER := 1;
        l_has_concept_types NUMBER := 1;
    
    BEGIN
        g_error := 'Get list of concept types and task types from table comm_order_type';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
    
        -- Validation of input values (task types)
        IF i_ids_task_types IS NULL
        THEN
            l_has_task_types := 0;
        ELSIF i_ids_task_types.count = 0
        THEN
            l_has_task_types := 0;
        END IF;
    
        -- Validation of input values (concept types)
        IF i_ids_concept_types IS NULL
        THEN
            l_has_concept_types := 0;
        ELSIF i_ids_concept_types.count = 0
        THEN
            l_has_concept_types := 0;
        END IF;
    
        -- Collect the values according to the input values
        SELECT cot.id_comm_order_type, cot.id_task_type
          BULK COLLECT
          INTO o_ids_concept_types, o_ids_task_types
          FROM comm_order_type cot
         WHERE (l_has_concept_types = 0 OR
               cot.id_comm_order_type IN (SELECT column_value
                                             FROM TABLE(i_ids_concept_types)))
           AND (l_has_task_types = 0 OR
               cot.id_task_type IN (SELECT column_value
                                       FROM TABLE(i_ids_task_types)));
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => k_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => l_error);
        
    END;

    /**
    * Procedure to populate EA table
    *
    * @param i_id_concept_version     Institution tp rebuild the EA
    * @param i_ids_softwares          List of softwares to rebuild the EA
    * @param i_ids_task_types         List of task types identifiers to filter. If null, is not filtred
    * @param i_ids_concept_types      List of concept types identifiers to filter. If null, is not filtred
    *
    * @author                         Tiago Silva   (Updated by Humberto Cardoso)
    * @version                        2.6.3         (Updated in 2.8.0.0)
    * @since                          2014/02/14    (Updated in 2019/09/02) 
    */
    PROCEDURE populate_ea
    (
        i_id_institution    IN NUMBER,
        i_ids_softwares     IN table_number,
        i_ids_task_types    IN table_number DEFAULT NULL,
        i_ids_concept_types IN table_number DEFAULT NULL
    ) IS
        l_func_name CONSTANT t_low_char := 'POPULATE_EA';
    
        CURSOR s_cur
        (
            l_id_institution  IN t_big_num,
            l_id_software     IN t_big_num,
            l_id_task_type    IN t_big_num,
            l_id_concept_type IN t_big_num
        ) IS
            SELECT id_comm_order,
                   id_terminology_version,
                   id_terminology,
                   version,
                   dt_version_start,
                   dt_version_end,
                   flg_active_term_vers,
                   ttt.id_terminology_mkt,
                   ttt.id_market,
                   ttt.id_institution_term_vers,
                   ttt.id_institution_conc_term,
                   id_task_type_term_vers,
                   id_task_type_conc_term,
                   id_software_term_vers,
                   id_software_conc_term,
                   id_dep_clin_serv,
                   id_category_cncpt_vers,
                   id_category_cncpt_term,
                   id_professional,
                   id_language,
                   id_concept_version,
                   id_cncpt_vrs_inst_owner,
                   id_concept,
                   id_concept_inst_owner,
                   ttt.concept_code,
                   id_concept_term,
                   id_cncpt_trm_inst_owner,
                   code_concept_term,
                   ttt.flg_type_concept_term,
                   rank,
                   internal_name_term_type,
                   id_concept_type,
                   code_concept_type_name,
                   ttt.tp_cpt_path.concept_path  AS concept_path,
                   ttt.tp_cpt_path.concept_level AS concept_level,
                   cpt_trm_uid,
                   cpt_vrs_uid,
                   cpt_vrs_uid_parent
              FROM (SELECT (SELECT ora_hash(lpad(mct.id_concept_term, 24, 0) || lpad(mct.id_cncpt_trm_inst_owner, 24, 0) ||
                                            lpad(mct.id_concept_version, 24, 0) ||
                                            lpad(mct.id_cncpt_vrs_inst_owner, 24, 0))
                              FROM dual) id_comm_order,
                           --TERMINOLOGY
                           tv.id_terminology_version,
                           mtv.id_terminology,
                           mtv.version,
                           mtv.dt_version_start,
                           mtv.dt_version_end,
                           mtv.flg_active            flg_active_term_vers,
                           --MKT
                           mtv.id_terminology_mkt id_terminology_mkt,
                           mtv.id_market          id_market,
                           --INST
                           mtv.id_institution id_institution_term_vers,
                           mct.id_institution id_institution_conc_term,
                           --TASK_TYPE
                           mtv.id_task_type  id_task_type_term_vers,
                           cttt.id_task_type id_task_type_conc_term,
                           --SFW
                           mtv.id_software id_software_term_vers,
                           mct.id_software id_software_conc_term,
                           --DEP_CLIN_SERV
                           mct.id_dep_clin_serv,
                           --CATEGORY
                           nvl(mcva.id_category, k_category_minus_one) id_category_cncpt_vers,
                           nvl(mct.id_category, k_category_minus_one) id_category_cncpt_term,
                           --PROF
                           mct.id_professional,
                           --LANG
                           mtv.id_language,
                           --CONCEPT_VERS
                           mct.id_concept_version,
                           mct.id_cncpt_vrs_inst_owner,
                           --CONCEPT
                           c.id_concept,
                           c.id_inst_owner id_concept_inst_owner,
                           c.code          concept_code,
                           --CONCEPT_TERM
                           mct.id_concept_term,
                           mct.id_cncpt_trm_inst_owner,
                           cttt.code_concept_term,
                           -- mct.id_inst_owner id_mct_inst_owner,
                           mct.flg_type      flg_type_concept_term,
                           mct.rank,
                           ctt.internal_name internal_name_term_type,
                           --CONCEPT_TYPE
                           ctr.id_concept_type id_concept_type,
                           ctype.code_concept_type_name,
                           (SELECT pk_coding_terminology.get_concept_path_uids(mct.id_concept_version,
                                                                               mct.id_cncpt_vrs_inst_owner,
                                                                               ctr.id_concept_type)
                              FROM dual) tp_cpt_path,
                           (SELECT ora_hash(lpad(mct.id_concept_term, 24, 0) || lpad(mct.id_cncpt_trm_inst_owner, 24, 0))
                              FROM dual) cpt_trm_uid,
                           (SELECT ora_hash(lpad(mct.id_concept_version, 24, 0) ||
                                            lpad(mct.id_cncpt_vrs_inst_owner, 24, 0))
                              FROM dual) cpt_vrs_uid,
                           (SELECT pk_coding_terminology.get_parent_uid(i_concept            => c.id_concept,
                                                                        i_concept_inst_owner => c.id_inst_owner,
                                                                        i_terminology_ver    => tv.id_terminology_version,
                                                                        i_concept_type       => ctr.id_concept_type)
                              FROM dual) cpt_vrs_uid_parent
                    --
                    -- [MSI_TERMINOLOGY_VERSION]
                      FROM msi_termin_version mtv
                    -- [TERMINOLOGY_VERSION]
                      JOIN terminology_version tv
                        ON tv.id_terminology = mtv.id_terminology
                       AND tv.version = mtv.version
                       AND tv.id_terminology_mkt = mtv.id_terminology_mkt
                       AND tv.id_language = mtv.id_language
                    -- [CONCEPT_VERSION]
                      JOIN concept_version cv
                        ON cv.id_terminology_version = tv.id_terminology_version
                    -- [MSI_CNCPT_VERS_ATTRIB]
                      JOIN msi_cncpt_vers_attrib mcva
                        ON mcva.id_terminology_version = cv.id_terminology_version
                       AND mcva.id_concept = cv.id_concept
                       AND mcva.id_concept_inst_owner = cv.id_concept_inst_owner
                       AND mcva.id_institution = mtv.id_institution
                       AND mcva.id_software = mtv.id_software
                    -- [CONCEPT]
                      JOIN concept c
                        ON c.id_concept = cv.id_concept
                       AND c.id_inst_owner = cv.id_concept_inst_owner
                       AND c.id_terminology = tv.id_terminology
                    -- [CONCEPT_TERM]
                      JOIN concept_term ct
                        ON ct.id_concept_vers_start = cv.id_concept_version
                       AND ct.id_concept_vers_end = cv.id_concept_version
                       AND ct.id_cncpt_vrs_inst_owner = cv.id_inst_owner
                    -- [CONCEPT_TERM_TASK_TYPE]
                      JOIN concept_term_task_type cttt
                        ON cttt.id_concept_term = ct.id_concept_term
                       AND cttt.id_cncpt_trm_inst_owner = ct.id_inst_owner
                       AND cttt.id_task_type = mtv.id_task_type
                    -- [CONCEPT_TERM_TYPE]
                      JOIN concept_term_type ctt
                        ON ctt.id_concept_term_type = ct.id_concept_term_type
                    -- [CONCEPT_TYPE_REL]
                      JOIN concept_type_rel ctr
                        ON ctr.id_terminology = mtv.id_terminology
                       AND ctr.id_concept = c.id_concept
                       AND ctr.id_concept_inst_owner = c.id_inst_owner
                       AND ctr.id_inst_owner = c.id_inst_owner
                    -- [CONCEPT_TYPE]
                      JOIN concept_type ctype
                        ON ctr.id_concept_type = ctype.id_concept_type
                    -- [MSI_CONCEPT_TERM]
                      JOIN (SELECT id_concept_term,
                                  id_cncpt_trm_inst_owner,
                                  id_concept_version,
                                  id_cncpt_vrs_inst_owner,
                                  id_inst_owner,
                                  id_institution,
                                  id_software,
                                  id_dep_clin_serv,
                                  id_professional,
                                  gender,
                                  age_min,
                                  age_max,
                                  rank,
                                  flg_active,
                                  id_category,
                                  id_unit_measure_min,
                                  id_unit_measure_max,
                                  flg_type
                             FROM (SELECT id_concept_term,
                                          id_cncpt_trm_inst_owner,
                                          id_concept_version,
                                          id_cncpt_vrs_inst_owner,
                                          id_inst_owner,
                                          id_institution,
                                          id_software,
                                          id_dep_clin_serv,
                                          id_professional,
                                          gender,
                                          age_min,
                                          age_max,
                                          rank,
                                          flg_type,
                                          flg_active,
                                          id_category,
                                          id_unit_measure_min,
                                          id_unit_measure_max,
                                          row_number() over(PARTITION BY id_concept_term, id_cncpt_trm_inst_owner, id_concept_version, id_cncpt_vrs_inst_owner, id_inst_owner, id_institution, id_software, id_dep_clin_serv, id_professional, gender, age_min, age_max, rank, id_category, id_unit_measure_min, id_unit_measure_max ORDER BY id_cncpt_trm_inst_owner DESC, id_cncpt_vrs_inst_owner DESC, id_inst_owner DESC) AS rn
                                     FROM msi_concept_term int_mct
                                    WHERE int_mct.id_institution = l_id_institution
                                      AND int_mct.id_software = l_id_software
                                      AND int_mct.flg_active = k_yes)
                            WHERE rn = 1) mct
                        ON mct.id_concept_term = ct.id_concept_term
                       AND mct.id_cncpt_trm_inst_owner = ct.id_inst_owner
                       AND mct.id_concept_version = cv.id_concept_version
                       AND mct.id_cncpt_vrs_inst_owner = cv.id_inst_owner
                       AND mct.id_institution = mtv.id_institution
                       AND mct.id_software = mtv.id_software
                    
                     WHERE mct.flg_active = k_yes
                       AND ct.flg_available = k_yes
                       AND mtv.id_task_type = l_id_task_type
                       AND cttt.id_task_type = l_id_task_type
                       AND mcva.flg_active = k_yes
                       AND ctr.id_concept_type = l_id_concept_type
                          -- The concept term must have a preferred term
                       AND EXISTS (SELECT 1
                              FROM concept_term ct1
                              JOIN concept_term_type ctt1
                                ON ctt1.id_concept_term_type = ct1.id_concept_term_type
                             WHERE ct1.id_concept_vers_start = cv.id_concept_version
                               AND ct1.id_concept_vers_end = cv.id_concept_version
                               AND ct1.flg_available = k_yes
                               AND ctt1.internal_name = k_pref_term_str)
                       AND mtv.id_institution = l_id_institution
                       AND mtv.id_software = l_id_software) ttt;
    
        TYPE fetch_array IS TABLE OF s_cur%ROWTYPE;
        s_array fetch_array;
    
        l_errors     PLS_INTEGER;
        e_dml_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_dml_errors, -24381);
    
        -- Store the filter of task types and concept types
        l_ids_task_types    table_number;
        l_ids_concept_types table_number;
    
    BEGIN
        g_error := 'open r_inst cursor';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
    
        -- Validation
    
        -- Collect the task types and concept types
        load_concept_types_task_types(i_ids_task_types    => i_ids_task_types,
                                      i_ids_concept_types => i_ids_concept_types,
                                      o_ids_task_types    => l_ids_task_types,
                                      o_ids_concept_types => l_ids_concept_types);
    
        -- For each software to rebuild
        FOR i_soft IN 1 .. i_ids_softwares.count
        LOOP
        
            -- For each concept_type and task_type
            FOR i_tt_ct IN 1 .. l_ids_task_types.count
            LOOP
            
                g_error := 'open s_cur-> {i_id_institution:' || i_id_institution || --
                           ', i_id_software:' || i_ids_softwares(i_soft) || --
                           ', i_id_task_type:' || l_ids_task_types(i_tt_ct) || --
                           ', i_id_concept_type:' || l_ids_concept_types(i_tt_ct) || '}';
                pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
                --dbms_output.put_line(g_error);
            
                --Removes the current rows from EA
                BEGIN
                    DELETE comm_order_ea e
                     WHERE e.id_institution_conc_term = i_id_institution
                       AND e.id_software_conc_term = i_ids_softwares(i_soft)
                       AND e.id_concept_type = l_ids_concept_types(i_tt_ct)
                       AND e.id_task_type_conc_term = l_ids_task_types(i_tt_ct);
                    dbms_output.put_line('Records deleted from EA: ' || SQL%ROWCOUNT || ' -> ' || current_timestamp);
                END;
            
                OPEN s_cur(i_id_institution,
                           i_ids_softwares(i_soft),
                           l_ids_task_types(i_tt_ct),
                           l_ids_concept_types(i_tt_ct));
                LOOP
                    FETCH s_cur BULK COLLECT
                        INTO s_array;
                
                    dbms_output.put_line('Records collected: ' || to_char(s_array.count) || ' -> ' ||
                                         current_timestamp);
                
                    FORALL i IN 1 .. s_array.count SAVE EXCEPTIONS
                        INSERT INTO comm_order_ea
                            (id_comm_order,
                             id_terminology_version,
                             id_terminology,
                             version,
                             dt_version_start,
                             dt_version_end,
                             flg_active_term_vers,
                             id_terminology_mkt,
                             id_market,
                             id_institution_term_vers,
                             id_institution_conc_term,
                             id_task_type_term_vers,
                             id_task_type_conc_term,
                             id_software_term_vers,
                             id_software_conc_term,
                             id_dep_clin_serv,
                             id_category_cncpt_vers,
                             id_category_cncpt_term,
                             id_professional,
                             id_language,
                             id_concept_version,
                             id_cncpt_vrs_inst_owner,
                             id_concept,
                             id_concept_inst_owner,
                             concept_code,
                             id_concept_term,
                             id_cncpt_trm_inst_owner,
                             code_concept_term,
                             flg_type_concept_term,
                             rank,
                             internal_name_term_type,
                             id_concept_type,
                             code_concept_type_name,
                             concept_path,
                             concept_level,
                             cpt_trm_uid,
                             cpt_vrs_uid,
                             cpt_vrs_uid_parent)
                        VALUES
                            (s_array(i).id_comm_order,
                             s_array(i).id_terminology_version,
                             s_array(i).id_terminology,
                             s_array(i).version,
                             s_array(i).dt_version_start,
                             s_array(i).dt_version_end,
                             s_array(i).flg_active_term_vers,
                             s_array(i).id_terminology_mkt,
                             s_array(i).id_market,
                             s_array(i).id_institution_term_vers,
                             s_array(i).id_institution_conc_term,
                             s_array(i).id_task_type_term_vers,
                             s_array(i).id_task_type_conc_term,
                             s_array(i).id_software_term_vers,
                             s_array(i).id_software_conc_term,
                             s_array(i).id_dep_clin_serv,
                             s_array(i).id_category_cncpt_vers,
                             s_array(i).id_category_cncpt_term,
                             s_array(i).id_professional,
                             s_array(i).id_language,
                             s_array(i).id_concept_version,
                             s_array(i).id_cncpt_vrs_inst_owner,
                             s_array(i).id_concept,
                             s_array(i).id_concept_inst_owner,
                             s_array(i).concept_code,
                             s_array(i).id_concept_term,
                             s_array(i).id_cncpt_trm_inst_owner,
                             s_array(i).code_concept_term,
                             s_array(i).flg_type_concept_term,
                             s_array(i).rank,
                             s_array(i).internal_name_term_type,
                             s_array(i).id_concept_type,
                             s_array(i).code_concept_type_name,
                             s_array(i).concept_path,
                             s_array(i).concept_level,
                             s_array(i).cpt_trm_uid,
                             s_array(i).cpt_vrs_uid,
                             s_array(i).cpt_vrs_uid_parent);
                
                    /*                    dbms_output.put_line('Records inserted: ' || to_char(SQL%ROWCOUNT) || ' -> ' || --
                    '{id_institution:' || to_char(i_id_institution) || --
                    ', i_id_software:' || i_ids_softwares(i_soft) || --
                    ', i_id_task_type:' || l_ids_task_types(i_tt_ct) || --
                    ', i_id_concept_type:' || l_ids_concept_types(i_tt_ct) || '}' || --
                    ' -> ' || current_timestamp);*/
                
                    EXIT WHEN s_cur%NOTFOUND;
                END LOOP;
                CLOSE s_cur;
            
            END LOOP;
        
        END LOOP;
    
    EXCEPTION
        WHEN e_dml_errors THEN
            l_errors := SQL%bulk_exceptions.count;
            dbms_output.put_line('Number of INSERT statements that failed: ' || l_errors);
        
        /*            FOR i IN 1 .. l_errors
        LOOP
            --dbms_output.put_line('Error #' || i || ' at ' || 'iteration #' || SQL%BULK_EXCEPTIONS(i).error_index);
            --dbms_output.put_line('Error message is ' || SQLERRM(-sql%BULK_EXCEPTIONS(i).error_code));
            --dbms_output.put_line('ID_TERMINOLOGY_VERSION: ' || s_array(SQL%BULK_EXCEPTIONS(i).error_index).id_terminology_version);
            --dbms_output.put_line('ID_INSTITUTION_CONC_TERM: ' || s_array(SQL%BULK_EXCEPTIONS(i).error_index).id_institution_conc_term);
            --dbms_output.put_line('ID_SOFTWARE_CONC_TERM: ' || s_array(SQL%BULK_EXCEPTIONS(i).error_index).id_software_conc_term);
            --dbms_output.put_line('ID_DEP_CLIN_SERV: ' || s_array(SQL%BULK_EXCEPTIONS(i).error_index).id_dep_clin_serv);
            --dbms_output.put_line('ID_CATEGORY_CNCPT_TERM: ' || s_array(SQL%BULK_EXCEPTIONS(i).error_index).id_category_cncpt_term);
            --dbms_output.put_line('ID_CONCEPT_TERM: ' || s_array(SQL%BULK_EXCEPTIONS(i).error_index).id_concept_term);
            --dbms_output.put_line('ID_CNCPT_TRM_INST_OWNER: ' || s_array(SQL%BULK_EXCEPTIONS(i).error_index).id_cncpt_trm_inst_owner);
            --dbms_output.put_line('ID_TASK_TYPE_CONC_TERM: ' || s_array(SQL%BULK_EXCEPTIONS(i).error_index).id_task_type_conc_term);
            --dbms_output.put_line('INTERNAL_NAME_TERM_TYPE: ' || s_array(SQL%BULK_EXCEPTIONS(i).error_index).internal_name_term_type);
            --dbms_output.put_line('ID_CONCEPT_TYPE: ' || s_array(SQL%BULK_EXCEPTIONS(i).error_index).id_concept_type);
        END LOOP;*/
        WHEN OTHERS THEN
            --dbms_output.put_line(SQLERRM);
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => l_func_name);
    END populate_ea;
    PROCEDURE populate_ea
    (
        i_id_institution         IN NUMBER,
        i_id_software            IN NUMBER,
        i_id_terminology_version IN NUMBER,
        i_id_concept_term        IN NUMBER,
        i_id_concept_type        IN NUMBER
        
    ) IS
        l_func_name CONSTANT t_low_char := 'POPULATE_EA';
    
        CURSOR s_cur(ic_id_task_type IN t_big_num) IS
            SELECT id_comm_order,
                   id_terminology_version,
                   id_terminology,
                   version,
                   dt_version_start,
                   dt_version_end,
                   flg_active_term_vers,
                   ttt.id_terminology_mkt,
                   ttt.id_market,
                   ttt.id_institution_term_vers,
                   ttt.id_institution_conc_term,
                   id_task_type_term_vers,
                   id_task_type_conc_term,
                   id_software_term_vers,
                   id_software_conc_term,
                   id_dep_clin_serv,
                   id_category_cncpt_vers,
                   id_category_cncpt_term,
                   id_professional,
                   id_language,
                   id_concept_version,
                   id_cncpt_vrs_inst_owner,
                   id_concept,
                   id_concept_inst_owner,
                   ttt.concept_code,
                   id_concept_term,
                   id_cncpt_trm_inst_owner,
                   code_concept_term,
                   ttt.flg_type_concept_term,
                   rank,
                   internal_name_term_type,
                   id_concept_type,
                   code_concept_type_name,
                   ttt.tp_cpt_path.concept_path  AS concept_path,
                   ttt.tp_cpt_path.concept_level AS concept_level,
                   cpt_trm_uid,
                   cpt_vrs_uid,
                   cpt_vrs_uid_parent
              FROM (SELECT (SELECT ora_hash(lpad(mct.id_concept_term, 24, 0) || lpad(mct.id_cncpt_trm_inst_owner, 24, 0) ||
                                            lpad(mct.id_concept_version, 24, 0) ||
                                            lpad(mct.id_cncpt_vrs_inst_owner, 24, 0))
                              FROM dual) id_comm_order,
                           --TERMINOLOGY
                           tv.id_terminology_version,
                           mtv.id_terminology,
                           mtv.version,
                           mtv.dt_version_start,
                           mtv.dt_version_end,
                           mtv.flg_active            flg_active_term_vers,
                           --MKT
                           mtv.id_terminology_mkt id_terminology_mkt,
                           mtv.id_market          id_market,
                           --INST
                           mtv.id_institution id_institution_term_vers,
                           mct.id_institution id_institution_conc_term,
                           --TASK_TYPE
                           mtv.id_task_type  id_task_type_term_vers,
                           cttt.id_task_type id_task_type_conc_term,
                           --SFW
                           mtv.id_software id_software_term_vers,
                           mct.id_software id_software_conc_term,
                           --DEP_CLIN_SERV
                           mct.id_dep_clin_serv,
                           --CATEGORY
                           nvl(mcva.id_category, k_category_minus_one) id_category_cncpt_vers,
                           nvl(mct.id_category, k_category_minus_one) id_category_cncpt_term,
                           --PROF
                           mct.id_professional,
                           --LANG
                           mtv.id_language,
                           --CONCEPT_VERS
                           mct.id_concept_version,
                           mct.id_cncpt_vrs_inst_owner,
                           --CONCEPT
                           c.id_concept,
                           c.id_inst_owner id_concept_inst_owner,
                           c.code          concept_code,
                           --CONCEPT_TERM
                           mct.id_concept_term,
                           mct.id_cncpt_trm_inst_owner,
                           cttt.code_concept_term,
                           -- mct.id_inst_owner id_mct_inst_owner,
                           mct.flg_type      flg_type_concept_term,
                           mct.rank,
                           ctt.internal_name internal_name_term_type,
                           --CONCEPT_TYPE
                           ctr.id_concept_type id_concept_type,
                           ctype.code_concept_type_name,
                           (SELECT pk_coding_terminology.get_concept_path_uids(mct.id_concept_version,
                                                                               mct.id_cncpt_vrs_inst_owner,
                                                                               ctr.id_concept_type)
                              FROM dual) tp_cpt_path,
                           (SELECT ora_hash(lpad(mct.id_concept_term, 24, 0) || lpad(mct.id_cncpt_trm_inst_owner, 24, 0))
                              FROM dual) cpt_trm_uid,
                           (SELECT ora_hash(lpad(mct.id_concept_version, 24, 0) ||
                                            lpad(mct.id_cncpt_vrs_inst_owner, 24, 0))
                              FROM dual) cpt_vrs_uid,
                           (SELECT pk_coding_terminology.get_parent_uid(i_concept            => c.id_concept,
                                                                        i_concept_inst_owner => c.id_inst_owner,
                                                                        i_terminology_ver    => tv.id_terminology_version,
                                                                        i_concept_type       => ctr.id_concept_type)
                              FROM dual) cpt_vrs_uid_parent
                    --
                    -- [MSI_TERMINOLOGY_VERSION]
                      FROM msi_termin_version mtv
                    -- [TERMINOLOGY_VERSION]
                      JOIN terminology_version tv
                        ON tv.id_terminology = mtv.id_terminology
                       AND tv.version = mtv.version
                       AND tv.id_terminology_mkt = mtv.id_terminology_mkt
                       AND tv.id_language = mtv.id_language
                    -- [CONCEPT_VERSION]
                      JOIN concept_version cv
                        ON cv.id_terminology_version = tv.id_terminology_version
                    -- [MSI_CNCPT_VERS_ATTRIB]
                      JOIN msi_cncpt_vers_attrib mcva
                        ON mcva.id_terminology_version = cv.id_terminology_version
                       AND mcva.id_concept = cv.id_concept
                       AND mcva.id_concept_inst_owner = cv.id_concept_inst_owner
                       AND mcva.id_institution = mtv.id_institution
                       AND mcva.id_software = mtv.id_software
                    -- [CONCEPT]
                      JOIN concept c
                        ON c.id_concept = cv.id_concept
                       AND c.id_inst_owner = cv.id_concept_inst_owner
                       AND c.id_terminology = tv.id_terminology
                    -- [CONCEPT_TERM]
                      JOIN concept_term ct
                        ON ct.id_concept_vers_start = cv.id_concept_version
                       AND ct.id_concept_vers_end = cv.id_concept_version
                       AND ct.id_cncpt_vrs_inst_owner = cv.id_inst_owner
                    -- [CONCEPT_TERM_TASK_TYPE]
                      JOIN concept_term_task_type cttt
                        ON cttt.id_concept_term = ct.id_concept_term
                       AND cttt.id_cncpt_trm_inst_owner = ct.id_inst_owner
                       AND cttt.id_task_type = mtv.id_task_type
                    -- [CONCEPT_TERM_TYPE]
                      JOIN concept_term_type ctt
                        ON ctt.id_concept_term_type = ct.id_concept_term_type
                    -- [CONCEPT_TYPE_REL]
                      JOIN concept_type_rel ctr
                        ON ctr.id_terminology = mtv.id_terminology
                       AND ctr.id_concept = c.id_concept
                       AND ctr.id_concept_inst_owner = c.id_inst_owner
                       AND ctr.id_inst_owner = c.id_inst_owner
                    -- [CONCEPT_TYPE]
                      JOIN concept_type ctype
                        ON ctr.id_concept_type = ctype.id_concept_type
                    -- [MSI_CONCEPT_TERM]
                      JOIN (SELECT id_concept_term,
                                  id_cncpt_trm_inst_owner,
                                  id_concept_version,
                                  id_cncpt_vrs_inst_owner,
                                  id_inst_owner,
                                  id_institution,
                                  id_software,
                                  id_dep_clin_serv,
                                  id_professional,
                                  gender,
                                  age_min,
                                  age_max,
                                  rank,
                                  flg_active,
                                  id_category,
                                  id_unit_measure_min,
                                  id_unit_measure_max,
                                  flg_type
                             FROM (SELECT id_concept_term,
                                          id_cncpt_trm_inst_owner,
                                          id_concept_version,
                                          id_cncpt_vrs_inst_owner,
                                          id_inst_owner,
                                          id_institution,
                                          id_software,
                                          id_dep_clin_serv,
                                          id_professional,
                                          gender,
                                          age_min,
                                          age_max,
                                          rank,
                                          flg_type,
                                          flg_active,
                                          id_category,
                                          id_unit_measure_min,
                                          id_unit_measure_max,
                                          row_number() over(PARTITION BY id_concept_term, id_cncpt_trm_inst_owner, id_concept_version, id_cncpt_vrs_inst_owner, id_inst_owner, id_institution, id_software, id_dep_clin_serv, id_professional, gender, age_min, age_max, rank, id_category, id_unit_measure_min, id_unit_measure_max ORDER BY id_cncpt_trm_inst_owner DESC, id_cncpt_vrs_inst_owner DESC, id_inst_owner DESC) AS rn
                                     FROM msi_concept_term int_mct
                                    WHERE int_mct.id_institution = i_id_institution
                                      AND int_mct.id_software = i_id_software
                                      AND int_mct.flg_active = k_yes)
                            WHERE rn = 1) mct
                        ON mct.id_concept_term = ct.id_concept_term
                       AND mct.id_cncpt_trm_inst_owner = ct.id_inst_owner
                       AND mct.id_concept_version = cv.id_concept_version
                       AND mct.id_cncpt_vrs_inst_owner = cv.id_inst_owner
                       AND mct.id_institution = mtv.id_institution
                       AND mct.id_software = mtv.id_software
                    
                     WHERE mct.flg_active = k_yes
                       AND ct.flg_available = k_yes
                       AND mtv.id_task_type = ic_id_task_type
                       AND cttt.id_task_type = ic_id_task_type
                       AND mcva.flg_active = k_yes
                       AND ctr.id_concept_type = i_id_concept_type
                          -- The concept term must have a preferred term
                       AND EXISTS (SELECT 1
                              FROM concept_term ct1
                              JOIN concept_term_type ctt1
                                ON ctt1.id_concept_term_type = ct1.id_concept_term_type
                             WHERE ct1.id_concept_vers_start = cv.id_concept_version
                               AND ct1.id_concept_vers_end = cv.id_concept_version
                               AND ct1.flg_available = k_yes
                               AND ctt1.internal_name = k_pref_term_str)
                          --Adds the filter for the current context
                       AND mtv.id_institution = i_id_institution
                       AND mtv.id_software = i_id_software
                       AND ct.id_concept_term = i_id_concept_term
                       AND ctype.id_concept_type = i_id_concept_type) ttt;
    
        --Only one record can be collected because the PK is used
        l_cur s_cur%ROWTYPE;
    
        -- Store task types for this concept type
        l_id_task_type NUMBER;
    
    BEGIN
        -- Validation of the input arguments
        IF i_id_institution IS NULL
        THEN
            raise_application_error(er_argument_null, 'The argument i_id_institution cannot be null!');
        END IF;
        IF i_id_software IS NULL
        THEN
            raise_application_error(er_argument_null, 'The argument i_id_software cannot be null!');
        END IF;
        IF i_id_terminology_version IS NULL
        THEN
            raise_application_error(er_argument_null, 'The argument i_id_terminology_version cannot be null!');
        END IF;
        IF i_id_concept_term IS NULL
        THEN
            raise_application_error(er_argument_null, 'The argument i_id_concept_term cannot be null!');
        END IF;
        IF i_id_concept_type IS NULL
        THEN
            raise_application_error(er_argument_null, 'The argument i_id_concept_type cannot be null!');
        END IF;
    
        g_error := 'open r_inst cursor';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
    
        --Loop for instituition is not needed
        g_error := 'open s_cur->inst=' || i_id_institution;
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
    
        -- Collect the task type for this concept type
        SELECT cot.id_task_type
          INTO l_id_task_type
          FROM comm_order_type cot
         WHERE cot.id_comm_order_type = i_id_concept_type;
    
        --Only one record can be collected because the PK is used
        OPEN s_cur(l_id_task_type);
        FETCH s_cur
            INTO l_cur;
    
        CLOSE s_cur;
    
        BEGIN
            --Removes the current record from the ea
            BEGIN
                DELETE comm_order_ea e
                 WHERE e.id_terminology_version = i_id_terminology_version
                   AND e.id_institution_conc_term = i_id_institution
                   AND e.id_software_conc_term = i_id_software
                   AND e.id_concept_term = i_id_concept_term
                   AND e.id_concept_type = i_id_concept_type;
            END;
        
            -- If the record is collected
            IF l_cur.id_comm_order IS NOT NULL
            THEN
                --Insert the record
                INSERT INTO comm_order_ea
                    (id_comm_order,
                     id_terminology_version,
                     id_terminology,
                     version,
                     dt_version_start,
                     dt_version_end,
                     flg_active_term_vers,
                     id_terminology_mkt,
                     id_market,
                     id_institution_term_vers,
                     id_institution_conc_term,
                     id_task_type_term_vers,
                     id_task_type_conc_term,
                     id_software_term_vers,
                     id_software_conc_term,
                     id_dep_clin_serv,
                     id_category_cncpt_vers,
                     id_category_cncpt_term,
                     id_professional,
                     id_language,
                     id_concept_version,
                     id_cncpt_vrs_inst_owner,
                     id_concept,
                     id_concept_inst_owner,
                     concept_code,
                     id_concept_term,
                     id_cncpt_trm_inst_owner,
                     code_concept_term,
                     flg_type_concept_term,
                     rank,
                     internal_name_term_type,
                     id_concept_type,
                     code_concept_type_name,
                     concept_path,
                     concept_level,
                     cpt_trm_uid,
                     cpt_vrs_uid,
                     cpt_vrs_uid_parent)
                VALUES
                    (l_cur.id_comm_order,
                     l_cur.id_terminology_version,
                     l_cur.id_terminology,
                     l_cur.version,
                     l_cur.dt_version_start,
                     l_cur.dt_version_end,
                     l_cur.flg_active_term_vers,
                     l_cur.id_terminology_mkt,
                     l_cur.id_market,
                     l_cur.id_institution_term_vers,
                     l_cur.id_institution_conc_term,
                     l_cur.id_task_type_term_vers,
                     l_cur.id_task_type_conc_term,
                     l_cur.id_software_term_vers,
                     l_cur.id_software_conc_term,
                     l_cur.id_dep_clin_serv,
                     l_cur.id_category_cncpt_vers,
                     l_cur.id_category_cncpt_term,
                     l_cur.id_professional,
                     l_cur.id_language,
                     l_cur.id_concept_version,
                     l_cur.id_cncpt_vrs_inst_owner,
                     l_cur.id_concept,
                     l_cur.id_concept_inst_owner,
                     l_cur.concept_code,
                     l_cur.id_concept_term,
                     l_cur.id_cncpt_trm_inst_owner,
                     l_cur.code_concept_term,
                     l_cur.flg_type_concept_term,
                     l_cur.rank,
                     l_cur.internal_name_term_type,
                     l_cur.id_concept_type,
                     l_cur.code_concept_type_name,
                     l_cur.concept_path,
                     l_cur.concept_level,
                     l_cur.cpt_trm_uid,
                     l_cur.cpt_vrs_uid,
                     l_cur.cpt_vrs_uid_parent);
            
            END IF;
        END;
    
    END populate_ea;

    /**
    * Process insert/update events on Patient education into TASK_TIMELINE_EA.
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_event_type            Event type
    * @param   i_rowids                Changed records rowids list
    * @param   i_src_table             Source table name
    * @param   i_list_columns          Changed column names list
    * @param   i_dg_table              Easy access table name
    *
    * @author  ANA.MONTEIRO
    * @version 2.6.3
    * @since   05-03-2014
    */
    PROCEDURE set_task_timeline
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_event_type   IN VARCHAR2,
        i_rowids       IN table_varchar,
        i_src_table    IN VARCHAR2,
        i_list_columns IN table_varchar,
        i_dg_table     IN VARCHAR2
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_TASK_TIMELINE';
        l_ea_table  CONSTANT VARCHAR2(30 CHAR) := 'TASK_TIMELINE_EA';
        l_src_table CONSTANT VARCHAR2(30 CHAR) := 'COMM_ORDER_REQ';
        l_ea_row  task_timeline_ea%ROWTYPE;
        l_ea_rows ts_task_timeline_ea.task_timeline_ea_tc;
        l_rows    table_varchar := table_varchar();
        l_error   t_error_out;
    
        CURSOR c_comm_order_r IS
            SELECT cor.id_comm_order_req,
                   cor.id_patient,
                   cor.id_episode,
                   e.id_visit,
                   cor.id_institution,
                   cor.dt_req,
                   cor.id_prof_req,
                   cor.dt_begin,
                   cor.id_workflow,
                   cor.id_status,
                   cor.dt_status,
                   cor.id_concept_type id_comm_order_type,
                   cor.flg_priority,
                   CASE --dt_end
                        WHEN cor.id_status = pk_comm_orders.g_id_sts_completed THEN
                         cor.dt_status
                        ELSE
                         NULL
                    END dt_end,
                   CASE --flg_outdated
                        WHEN cor.id_status = pk_comm_orders.g_id_sts_ongoing THEN
                         pk_ea_logic_tasktimeline.g_flg_not_outdated --active                        
                        ELSE
                         pk_ea_logic_tasktimeline.g_flg_outdated
                    END flg_outdated,
                   CASE --flg_ongoing
                        WHEN cor.id_status = pk_comm_orders.g_id_sts_completed THEN
                         pk_prog_notes_constants.g_task_finalized_f
                        ELSE
                         pk_prog_notes_constants.g_task_ongoing_o
                    END flg_ongoing,
                   e.flg_status flg_status_epis,
                   cor.id_task_type
              FROM comm_order_req cor
              JOIN episode e
                ON cor.id_episode = e.id_episode
             WHERE cor.rowid IN (SELECT /*+dynamic_sampling(t 2)*/
                                  t.column_value row_id
                                   FROM TABLE(i_rowids) t)
               AND cor.id_status NOT IN (pk_comm_orders.g_id_sts_predf, pk_comm_orders.g_id_sts_draft);
    
        TYPE t_coll_comm_order_r IS TABLE OF c_comm_order_r%ROWTYPE;
        l_comm_order_r_rows t_coll_comm_order_r;
    
        l_sysdate TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_idx     PLS_INTEGER;
    BEGIN
        l_sysdate := current_timestamp;
        l_idx     := 0;
    
        -- validate arguments
        g_error := 'CALL t_data_gov_mnt.validate_arguments';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_src_table,
                                                 i_dg_table_name          => i_dg_table,
                                                 i_expected_table_name    => l_src_table,
                                                 i_expected_dg_table_name => l_ea_table,
                                                 i_list_columns           => i_list_columns)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- exit when no rowids are specified
        IF i_rowids IS NULL
           OR i_rowids.count < 1
        THEN
            RETURN;
        END IF;
    
        IF i_event_type IN (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update)
        THEN
            -- debug event
            g_error := 'processing insert or update event on ' || l_src_table || ' into ' || l_ea_table;
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        
            -- get comm orders req data from rowids
            g_error := 'OPEN c_comm_order_r';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            OPEN c_comm_order_r;
            FETCH c_comm_order_r BULK COLLECT
                INTO l_comm_order_r_rows;
            CLOSE c_comm_order_r;
        
            -- copy comm orders req data into rows collection
            IF l_comm_order_r_rows IS NOT NULL
               AND l_comm_order_r_rows.count > 0
            THEN
                -- set constant fields
                l_ea_row.id_tl_task        := pk_prog_notes_constants.g_task_communications;
                l_ea_row.table_name        := l_src_table;
                l_ea_row.flg_show_method   := pk_alert_constant.g_tl_oriented_episode;
                l_ea_row.dt_dg_last_update := l_sysdate;
                l_ea_row.flg_sos           := pk_alert_constant.g_no;
                l_ea_row.flg_normal        := pk_alert_constant.g_yes;
                l_ea_row.flg_has_comments  := pk_alert_constant.g_no;
            
                -- set variable fields
                FOR i IN 1 .. l_comm_order_r_rows.count
                LOOP
                    l_ea_row.id_task_refid := l_comm_order_r_rows(i).id_comm_order_req;
                
                    IF l_comm_order_r_rows(i)
                     .id_status IN (pk_comm_orders.g_id_sts_canceled, pk_comm_orders.g_id_sts_expired)
                        OR l_comm_order_r_rows(i).flg_status_epis = pk_alert_constant.g_epis_status_cancel
                    THEN
                        g_error := 'CALL TS_TASK_TIMELINE_EA.DEL';
                        pk_alertlog.log_info(text            => g_error,
                                             object_name     => g_package_name,
                                             sub_object_name => l_func_name);
                        ts_task_timeline_ea.del(id_task_refid_in => l_ea_row.id_task_refid,
                                                id_tl_task_in    => l_ea_row.id_tl_task);
                    ELSE
                        -- add row to rows collection
                        l_ea_row.id_patient     := l_comm_order_r_rows(i).id_patient;
                        l_ea_row.id_episode     := l_comm_order_r_rows(i).id_episode;
                        l_ea_row.id_visit       := l_comm_order_r_rows(i).id_visit;
                        l_ea_row.id_institution := l_comm_order_r_rows(i).id_institution;
                        l_ea_row.dt_req         := l_comm_order_r_rows(i).dt_req;
                        l_ea_row.id_prof_req    := l_comm_order_r_rows(i).id_prof_req;
                        l_ea_row.dt_begin       := l_comm_order_r_rows(i).dt_begin;
                        l_ea_row.dt_end         := l_comm_order_r_rows(i).dt_end;
                        l_ea_row.flg_status_req := l_comm_order_r_rows(i).id_status;
                        l_ea_row.flg_outdated   := l_comm_order_r_rows(i).flg_outdated;
                        l_ea_row.flg_ongoing    := l_comm_order_r_rows(i).flg_ongoing;
                        l_ea_row.dt_last_update := l_comm_order_r_rows(i).dt_status;
                        l_ea_row.rank           := pk_comm_orders.get_comm_order_req_rank(i_lang               => i_lang,
                                                                                          i_prof               => i_prof,
                                                                                          i_id_comm_order_type => l_comm_order_r_rows(i).id_comm_order_type,
                                                                                          i_id_workflow        => l_comm_order_r_rows(i).id_workflow,
                                                                                          i_id_status          => l_comm_order_r_rows(i).id_status,
                                                                                          i_flg_priority       => l_comm_order_r_rows(i).flg_priority,
                                                                                          i_id_task_type       => l_comm_order_r_rows(i).id_task_type); -- rank to be show in single page                    
                        l_ea_row.flg_type := CASE
                                                 WHEN l_comm_order_r_rows(i).id_comm_order_type = pk_comm_orders.g_restraint_order_type THEN
                                                  pk_prog_notes_constants.g_auto_pop_restraint_order
                                                 ELSE
                                                  NULL
                                             END;
                    
                        l_idx := l_idx + 1; -- this idx is used because an INDEX BY TABLE can be sparse. ts_task_timeline_ea.upd cannot handle sparse collections
                        l_ea_rows(l_idx) := l_ea_row;
                    
                    END IF;
                END LOOP;
            
                --if it was canceled there is nothing to insert or update
                IF l_ea_rows.count > 0
                THEN
                    -- add rows collection to easy access
                    IF i_event_type = t_data_gov_mnt.g_event_insert
                    THEN
                        g_error := 'CALL ts_task_timeline_ea.ins I';
                        pk_alertlog.log_info(text            => g_error,
                                             object_name     => g_package_name,
                                             sub_object_name => l_func_name);
                        ts_task_timeline_ea.ins(rows_in => l_ea_rows);
                    ELSIF i_event_type = t_data_gov_mnt.g_event_update
                    THEN
                        g_error := 'CALL ts_task_timeline_ea.upd';
                        pk_alertlog.log_info(text            => g_error,
                                             object_name     => g_package_name,
                                             sub_object_name => l_func_name);
                        ts_task_timeline_ea.upd(col_in => l_ea_rows, ignore_if_null_in => FALSE, rows_out => l_rows);
                    
                        IF l_rows.count = 0
                        THEN
                            g_error := 'CALL ts_task_timeline_ea.ins II';
                            pk_alertlog.log_info(text            => g_error,
                                                 object_name     => g_package_name,
                                                 sub_object_name => l_func_name);
                            ts_task_timeline_ea.ins(rows_in => l_ea_rows);
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RAISE;
    END set_task_timeline;

    PROCEDURE get_comm_order_plan_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_status    IN comm_order_plan.flg_status%TYPE,
        i_dt_plan       IN comm_order_plan.dt_plan_tstz%TYPE,
        i_dt_take       IN comm_order_plan.dt_take_tstz%TYPE,
        i_task_duration IN comm_order_req.task_duration%TYPE,
        i_req_status    IN comm_order_req.id_comm_order_req%TYPE,
        o_status_str    OUT VARCHAR2,
        o_status_msg    OUT VARCHAR2,
        o_status_icon   OUT VARCHAR2,
        o_status_flg    OUT VARCHAR2
    ) IS
    
        l_display_type  VARCHAR2(200) := '';
        l_back_color    VARCHAR2(200) := '';
        l_status_flg    VARCHAR2(200) := '';
        l_message_style VARCHAR2(200) := '';
        l_message_color VARCHAR2(200) := '';
        l_default_color VARCHAR2(200) := '';
        -- icon
        l_aux VARCHAR2(200);
        -- date
        l_date_begin VARCHAR2(200);
    
        l_sysdate TIMESTAMP(6) WITH LOCAL TIME ZONE;
    
    BEGIN
    
        l_sysdate := current_timestamp;
    
        -- l_date_begin        
        IF i_flg_status IS NOT NULL
        THEN
            IF i_req_status = pk_comm_orders.g_id_sts_draft
            THEN
                l_date_begin := NULL;
            ELSE
                IF i_dt_plan IS NULL
                THEN
                    l_date_begin := NULL;
                ELSE
                    IF i_dt_take IS NOT NULL
                    THEN
                        IF pk_date_utils.add_to_ltstz(i_dt_take, i_task_duration, 'MINUTE') < l_sysdate
                        THEN
                            l_date_begin := pk_date_utils.to_char_insttimezone(i_prof,
                                                                               pk_date_utils.add_to_ltstz(i_dt_take,
                                                                                                          i_task_duration,
                                                                                                          'MINUTE'),
                                                                               pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
                        ELSE
                            l_date_begin := pk_date_utils.to_char_insttimezone(i_prof,
                                                                               i_dt_take,
                                                                               pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
                        END IF;
                    ELSE
                        l_date_begin := pk_date_utils.to_char_insttimezone(i_prof,
                                                                           i_dt_plan,
                                                                           pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
                    END IF;
                END IF;
            END IF;
        ELSE
            l_date_begin := NULL;
        END IF;
    
        -- l_aux
        IF i_flg_status IS NOT NULL
        THEN
            IF i_req_status = pk_comm_orders.g_id_sts_draft
            THEN
                l_aux := 'COMM_ORDER_REQ.ID_STATUS';
            ELSIF i_flg_status IN (pk_comm_orders.g_comm_order_plan_executed,
                                   pk_comm_orders.g_comm_order_plan_monitorized,
                                   pk_comm_orders.g_comm_order_plan_not_executed,
                                   pk_comm_orders.g_comm_order_plan_discontinued,
                                   pk_comm_orders.g_comm_order_plan_expired,
                                   pk_comm_orders.g_comm_order_plan_cancel)
                  OR i_dt_plan IS NULL
            THEN
                l_aux := 'COMM_ORDER_PLAN.FLG_STATUS';
            ELSIF i_flg_status = pk_comm_orders.g_comm_order_plan_req
            THEN
                l_aux := pk_date_utils.to_char_insttimezone(i_prof,
                                                            i_dt_plan,
                                                            pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
            ELSE
                l_aux := 'COMM_ORDER_PLAN.FLG_STATUS';
            END IF;
        ELSE
            l_aux := 'COMM_ORDER_PLAN.FLG_STATUS';
        END IF;
    
        -- l_display_type
        IF i_flg_status IS NOT NULL
        THEN
            IF i_flg_status = pk_comm_orders.g_comm_order_plan_ongoing
               AND i_task_duration IS NOT NULL
            THEN
                l_display_type := pk_alert_constant.g_display_type_date_icon;
            ELSIF i_flg_status = pk_comm_orders.g_comm_order_plan_ongoing
                  AND i_task_duration IS NULL
            THEN
            
                l_date_begin   := NULL;
                l_display_type := pk_alert_constant.g_display_type_icon;
            
            ELSIF i_flg_status IN (pk_comm_orders.g_comm_order_plan_executed,
                                   pk_comm_orders.g_comm_order_plan_monitorized,
                                   pk_comm_orders.g_comm_order_plan_not_executed,
                                   pk_comm_orders.g_comm_order_plan_discontinued,
                                   pk_comm_orders.g_comm_order_plan_expired,
                                   pk_comm_orders.g_comm_order_plan_cancel)
                  OR i_dt_plan IS NULL
                  OR i_req_status = pk_comm_orders.g_id_sts_draft
            THEN
                l_display_type := pk_alert_constant.g_display_type_icon;
            ELSE
                l_display_type := pk_alert_constant.g_display_type_date;
            END IF;
        ELSE
            l_display_type := pk_alert_constant.g_display_type_icon;
        END IF;
    
        -- l_back_color
        IF i_flg_status IS NOT NULL
        THEN
            IF i_req_status = pk_comm_orders.g_id_sts_draft
            THEN
                l_back_color := pk_alert_constant.g_color_null;
            ELSE
                IF i_flg_status = pk_comm_orders.g_comm_order_plan_req
                THEN
                    IF i_dt_plan > l_sysdate
                    THEN
                        l_back_color := pk_alert_constant.g_color_green;
                    ELSE
                        l_back_color := pk_alert_constant.g_color_red;
                    END IF;
                ELSIF i_flg_status = pk_comm_orders.g_comm_order_plan_ongoing
                THEN
                    IF i_task_duration IS NULL
                    THEN
                        l_back_color := pk_alert_constant.g_color_null;
                    ELSIF pk_date_utils.add_to_ltstz(i_dt_take, i_task_duration, 'MINUTE') < l_sysdate
                    THEN
                        l_back_color := pk_alert_constant.g_color_red;
                    ELSE
                        l_back_color := pk_alert_constant.g_color_green;
                    END IF;
                ELSE
                    l_back_color := pk_alert_constant.g_color_null;
                END IF;
            END IF;
        ELSE
            l_back_color := pk_alert_constant.g_color_null;
        END IF;
    
        -- l_status_flg
        IF i_flg_status IS NOT NULL
        THEN
            IF i_req_status = pk_comm_orders.g_id_sts_draft
            THEN
                l_status_flg := pk_comm_orders.g_id_sts_draft;
            ELSE
                l_status_flg := i_flg_status;
            END IF;
        ELSE
            l_status_flg := pk_comm_orders.g_comm_order_plan_sos;
        END IF;
    
        -- l_message_style
        l_message_style := NULL;
    
        pk_utils.build_status_string(i_display_type  => l_display_type,
                                     i_flg_state     => l_status_flg,
                                     i_value_text    => l_aux,
                                     i_value_date    => nvl(l_date_begin, l_aux),
                                     i_value_icon    => l_aux,
                                     i_back_color    => l_back_color,
                                     i_message_style => l_message_style,
                                     i_message_color => l_message_color,
                                     i_default_color => l_default_color,
                                     o_status_str    => o_status_str,
                                     o_status_msg    => o_status_msg,
                                     o_status_icon   => o_status_icon,
                                     o_status_flg    => o_status_flg);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_comm_order_plan_status;

    FUNCTION get_comm_order_plan_status_flg
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_status    IN comm_order_plan.flg_status%TYPE,
        i_dt_plan       IN comm_order_plan.dt_plan_tstz%TYPE,
        i_dt_take       IN comm_order_plan.dt_take_tstz%TYPE,
        i_task_duration IN comm_order_req.task_duration%TYPE,
        i_req_status    IN comm_order_req.id_comm_order_req%TYPE
        
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(200);
    
    BEGIN
    
        get_comm_order_plan_status(i_lang          => i_lang,
                                   i_prof          => i_prof,
                                   i_flg_status    => i_flg_status,
                                   i_dt_plan       => i_dt_plan,
                                   i_dt_take       => i_dt_take,
                                   i_task_duration => i_task_duration,
                                   i_req_status    => i_req_status,
                                   o_status_str    => l_status_str,
                                   o_status_msg    => l_status_msg,
                                   o_status_icon   => l_status_icon,
                                   o_status_flg    => l_status_flg);
    
        RETURN l_status_flg;
    
    END get_comm_order_plan_status_flg;

    FUNCTION get_comm_order_plan_stat_icon
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_status    IN comm_order_plan.flg_status%TYPE,
        i_dt_plan       IN comm_order_plan.dt_plan_tstz%TYPE,
        i_dt_take       IN comm_order_plan.dt_take_tstz%TYPE,
        i_task_duration IN comm_order_req.task_duration%TYPE,
        i_req_status    IN comm_order_req.id_comm_order_req%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(200);
    
    BEGIN
    
        get_comm_order_plan_status(i_lang          => i_lang,
                                   i_prof          => i_prof,
                                   i_flg_status    => i_flg_status,
                                   i_dt_plan       => i_dt_plan,
                                   i_dt_take       => i_dt_take,
                                   i_task_duration => i_task_duration,
                                   i_req_status    => i_req_status,
                                   o_status_str    => l_status_str,
                                   o_status_msg    => l_status_msg,
                                   o_status_icon   => l_status_icon,
                                   o_status_flg    => l_status_flg);
    
        RETURN l_status_icon;
    
    END get_comm_order_plan_stat_icon;

    FUNCTION get_comm_order_plan_status_msg
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_status    IN comm_order_plan.flg_status%TYPE,
        i_dt_plan       IN comm_order_plan.dt_plan_tstz%TYPE,
        i_dt_take       IN comm_order_plan.dt_take_tstz%TYPE,
        i_task_duration IN comm_order_req.task_duration%TYPE,
        i_req_status    IN comm_order_req.id_comm_order_req%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(200);
    
    BEGIN
    
        get_comm_order_plan_status(i_lang          => i_lang,
                                   i_prof          => i_prof,
                                   i_flg_status    => i_flg_status,
                                   i_dt_plan       => i_dt_plan,
                                   i_dt_take       => i_dt_take,
                                   i_task_duration => i_task_duration,
                                   i_req_status    => i_req_status,
                                   o_status_str    => l_status_str,
                                   o_status_msg    => l_status_msg,
                                   o_status_icon   => l_status_icon,
                                   o_status_flg    => l_status_flg);
        RETURN l_status_msg;
    
    END get_comm_order_plan_status_msg;

    FUNCTION get_comm_order_plan_status_str
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_status    IN comm_order_plan.flg_status%TYPE,
        i_dt_plan       IN comm_order_plan.dt_plan_tstz%TYPE,
        i_dt_take       IN comm_order_plan.dt_take_tstz%TYPE,
        i_task_duration IN comm_order_req.task_duration%TYPE,
        i_req_status    IN comm_order_req.id_comm_order_req%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(200);
    
    BEGIN
    
        get_comm_order_plan_status(i_lang          => i_lang,
                                   i_prof          => i_prof,
                                   i_flg_status    => i_flg_status,
                                   i_dt_plan       => i_dt_plan,
                                   i_dt_take       => i_dt_take,
                                   i_task_duration => i_task_duration,
                                   i_req_status    => i_req_status,
                                   o_status_str    => l_status_str,
                                   o_status_msg    => l_status_msg,
                                   o_status_icon   => l_status_icon,
                                   o_status_flg    => l_status_flg);
    
        RETURN l_status_str;
    
    END get_comm_order_plan_status_str;

    PROCEDURE set_grid_task
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_rowids table_varchar;
    
    BEGIN
    
        g_error := 'GET BPs ROWIDS';
        get_data_rowid(i_lang, i_prof, i_source_table_name, i_rowids, l_rowids);
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => 'GRID_TASK',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Process update event
        IF i_event_type IN (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update)
        THEN
            -- Loop through changed records
            g_error := 'LOOP UPDATED';
            IF i_rowids IS NOT NULL
               AND i_rowids.count > 0
            THEN
                ins_grid_task(i_lang => i_lang, i_prof => i_prof, i_rowids => l_rowids);
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => g_error);
    END set_grid_task;

    PROCEDURE ins_grid_task
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_rowids IN table_varchar
    ) IS
    
        l_grid_task      grid_task%ROWTYPE;
        l_grid_task_betw grid_task_between%ROWTYPE;
    
        l_prof           profissional := i_prof;
        l_id_institution episode.id_institution%TYPE;
        l_id_software    epis_info.id_software%TYPE;
    
    BEGIN
    
        -- Loop through changed records            
        FOR r_cur IN (SELECT *
                        FROM (SELECT cor.id_episode id_episode, cor.id_professional, cor.id_task_type
                                FROM (SELECT /*+opt_estimate (table mv rows=1)*/
                                       *
                                        FROM comm_order_req cor
                                       WHERE (cor.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                             *
                                                              FROM TABLE(i_rowids) t) OR i_rowids IS NULL)
                                         AND cor.id_status != pk_comm_orders.g_id_sts_draft) cor))
        LOOP
        
            l_grid_task      := NULL;
            l_grid_task_betw := NULL;
        
            IF i_prof IS NULL
            THEN
                BEGIN
                    SELECT e.id_institution, ei.id_software
                      INTO l_id_institution, l_id_software
                      FROM episode e
                      JOIN epis_info ei
                        ON ei.id_episode = e.id_episode
                     WHERE e.id_episode = r_cur.id_episode;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_id_institution := NULL;
                        l_id_software    := NULL;
                END;
            
                IF r_cur.id_professional IS NULL
                   OR l_id_institution IS NULL
                   OR l_id_software IS NULL
                THEN
                    CONTINUE;
                END IF;
            
                l_prof := profissional(r_cur.id_professional, l_id_institution, l_id_software);
            END IF;
        
            ins_grid_task_epis(i_lang         => i_lang,
                               i_prof         => l_prof,
                               i_id_episode   => r_cur.id_episode,
                               i_id_task_type => r_cur.id_task_type);
        END LOOP;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => g_error);
    END ins_grid_task;

    PROCEDURE ins_grid_task_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN grid_task.id_episode%TYPE,
        i_id_task_type IN task_type.id_task_type%TYPE
    ) IS
    
        l_grid_task grid_task%ROWTYPE;
    
        l_shortcut sys_shortcut.id_sys_shortcut%TYPE;
    
        l_dt_str_1 VARCHAR2(200 CHAR);
        l_dt_str_2 VARCHAR2(200 CHAR);
        l_dt_1     VARCHAR2(200 CHAR);
        l_dt_2     VARCHAR2(200 CHAR);
    
        l_task_type           task_type.id_task_type%TYPE;
        l_status_string       grid_task.common_order%TYPE;
        l_id_category         category.id_category%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
    
        l_error_out t_error_out;
    
    BEGIN
    
        g_error := 'PK_ACCESS.GET_ID_SHORTCUT';
        IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_intern_name => 'CPOE_GRID',
                                         o_id_shortcut => l_shortcut,
                                         o_error       => l_error_out)
        THEN
            l_shortcut := 0;
        END IF;
    
        l_id_category         := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof);
    
        IF i_id_task_type = pk_alert_constant.g_task_medical_orders
        THEN
            UPDATE grid_task a
               SET a.medical_order = NULL
             WHERE id_episode = i_id_episode;
        ELSE
            UPDATE grid_task a
               SET a.common_order = NULL
             WHERE id_episode = i_id_episode;
        END IF;
    
        SELECT MAX(status_string) status_string
          INTO l_status_string
          FROM (SELECT decode(rank,
                               1,
                               pk_utils.get_status_string(i_lang,
                                                          i_prof,
                                                          pk_ea_logic_comm_orders.get_comm_order_plan_status_str(i_lang,
                                                                                                                 i_prof,
                                                                                                                 CASE
                                                                                                                     WHEN t.flg_prn = pk_alert_constant.g_yes
                                                                                                                          AND t.flg_status = pk_comm_orders.g_comm_order_plan_req THEN
                                                                                                                      NULL
                                                                                                                     ELSE
                                                                                                                      t.flg_status
                                                                                                                 END,
                                                                                                                 t.dt_plan_tstz,
                                                                                                                 t.dt_take_tstz,
                                                                                                                 t.task_duration,
                                                                                                                 t.id_status),
                                                          pk_ea_logic_comm_orders.get_comm_order_plan_status_msg(i_lang,
                                                                                                                 i_prof,
                                                                                                                 CASE
                                                                                                                     WHEN t.flg_prn = pk_alert_constant.g_yes
                                                                                                                          AND t.flg_status = pk_comm_orders.g_comm_order_plan_req THEN
                                                                                                                      NULL
                                                                                                                     ELSE
                                                                                                                      t.flg_status
                                                                                                                 END,
                                                                                                                 t.dt_plan_tstz,
                                                                                                                 t.dt_take_tstz,
                                                                                                                 t.task_duration,
                                                                                                                 t.id_status),
                                                          pk_ea_logic_comm_orders.get_comm_order_plan_stat_icon(i_lang,
                                                                                                                i_prof,
                                                                                                                CASE
                                                                                                                    WHEN t.flg_prn = pk_alert_constant.g_yes
                                                                                                                         AND t.flg_status = pk_comm_orders.g_comm_order_plan_req THEN
                                                                                                                     NULL
                                                                                                                    ELSE
                                                                                                                     t.flg_status
                                                                                                                END,
                                                                                                                t.dt_plan_tstz,
                                                                                                                t.dt_take_tstz,
                                                                                                                t.task_duration,
                                                                                                                t.id_status),
                                                          pk_ea_logic_comm_orders.get_comm_order_plan_status_flg(i_lang,
                                                                                                                 i_prof,
                                                                                                                 CASE
                                                                                                                     WHEN t.flg_prn = pk_alert_constant.g_yes
                                                                                                                          AND t.flg_status = pk_comm_orders.g_comm_order_plan_req THEN
                                                                                                                      NULL
                                                                                                                     ELSE
                                                                                                                      t.flg_status
                                                                                                                 END,
                                                                                                                 t.dt_plan_tstz,
                                                                                                                 t.dt_take_tstz,
                                                                                                                 t.task_duration,
                                                                                                                 t.id_status)),
                               
                               NULL) status_string,
                       id_task_type
                  FROM (SELECT t.id_comm_order_req,
                               t.id_episode,
                               t.flg_time,
                               t.id_status,
                               t.flg_status_det,
                               t.dt_begin,
                               t.dt_req,
                               t.id_task_type,
                               t.dt_plan_tstz,
                               t.dt_take_tstz,
                               t.task_duration,
                               t.flg_status,
                               t.flg_prn,
                               row_number() over(ORDER BY t.rank) rank
                          FROM (SELECT t.*,
                                       pk_comm_orders.get_comm_order_req_rank(t.rank_cot,
                                                                              pk_workflow.get_status_rank(i_lang,
                                                                                                          i_prof,
                                                                                                          t.id_workflow,
                                                                                                          t.id_status,
                                                                                                          l_id_category,
                                                                                                          l_id_profile_template,
                                                                                                          NULL,
                                                                                                          table_varchar()),
                                                                              pk_sysdomain.get_rank(i_lang,
                                                                                                    'COMM_ORDER_REQ.FLG_PRIORITY',
                                                                                                    t.flg_priority)) rank
                                  FROM (SELECT cor.id_comm_order_req,
                                               cor.id_episode,
                                               NULL                  flg_time,
                                               cor.id_status,
                                               cor.id_workflow,
                                               cor.id_status         flg_status_det,
                                               cor.dt_req,
                                               cor.dt_begin,
                                               cor.id_task_type,
                                               cor.flg_priority,
                                               cot.rank              rank_cot,
                                               cop.dt_plan_tstz,
                                               cop.dt_take_tstz,
                                               cor.task_duration,
                                               cop.flg_status,
                                               cor.flg_prn
                                          FROM comm_order_req cor
                                          JOIN comm_order_type cot
                                            ON cor.id_concept_type = cot.id_comm_order_type
                                           AND cot.id_task_type = cor.id_task_type
                                          LEFT JOIN comm_order_plan cop
                                            ON cor.id_comm_order_req = cop.id_comm_order_req
                                          JOIN episode e
                                            ON cor.id_episode = e.id_episode
                                         WHERE e.id_episode = i_id_episode
                                           AND cor.id_task_type = i_id_task_type
                                           AND cor.id_status = pk_comm_orders.g_id_sts_ongoing) t) t) t
                 WHERE rank = 1) t;
    
        g_error := 'GET SHORTCUT - DOCTOR';
        IF l_status_string IS NOT NULL
        THEN
            IF regexp_like(l_status_string, '^\|D')
            THEN
                l_dt_str_1 := regexp_replace(l_status_string, '^\|D\w{0,1}\|(\d{14})\|.*\|\d{14}\|.*', '\1');
                l_dt_str_2 := regexp_replace(l_status_string, '^\|D\w{0,1}\|\d{14}\|.*\|(\d{14})\|.*', '\1');
            
                l_dt_1 := pk_date_utils.to_char_insttimezone(i_prof,
                                                             pk_date_utils.get_string_tstz(i_lang,
                                                                                           i_prof,
                                                                                           l_dt_str_1,
                                                                                           NULL),
                                                             'YYYYMMDDHH24MISS TZR');
            
                l_dt_2 := pk_date_utils.to_char_insttimezone(i_prof,
                                                             pk_date_utils.get_string_tstz(i_lang,
                                                                                           i_prof,
                                                                                           l_dt_str_2,
                                                                                           NULL),
                                                             'YYYYMMDDHH24MISS TZR');
            
                IF l_dt_str_1 = l_dt_str_2
                THEN
                    l_status_string := regexp_replace(l_status_string, l_dt_str_1, l_dt_1);
                ELSE
                    l_status_string := regexp_replace(l_status_string, l_dt_str_1, l_dt_1);
                    l_status_string := regexp_replace(l_status_string, l_dt_str_2, l_dt_2);
                END IF;
            ELSE
                l_dt_str_2      := regexp_replace(l_status_string, '^\|\w{0,2}\|.*\|(\d{14})\|.*', '\1');
                l_dt_2          := pk_date_utils.to_char_insttimezone(i_prof,
                                                                      pk_date_utils.get_string_tstz(i_lang,
                                                                                                    i_prof,
                                                                                                    l_dt_str_2,
                                                                                                    NULL),
                                                                      'YYYYMMDDHH24MISS TZR');
                l_status_string := regexp_replace(l_status_string, l_dt_str_2, l_dt_2);
            END IF;
        
            l_grid_task.id_episode := i_id_episode;
        
            IF i_id_task_type = pk_alert_constant.g_task_medical_orders
            THEN
                l_grid_task.medical_order := l_shortcut || l_status_string;
            ELSE
                l_grid_task.common_order := l_shortcut || l_status_string;
            END IF;
        
            IF l_grid_task.id_episode IS NOT NULL
            THEN
                IF i_id_task_type = pk_alert_constant.g_task_medical_orders
                THEN
                    IF NOT pk_grid.update_grid_task(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_episode         => l_grid_task.id_episode,
                                                    medical_order_in  => l_grid_task.medical_order,
                                                    medical_order_nin => FALSE,
                                                    o_error           => l_error_out)
                    THEN
                        RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                    END IF;
                ELSE
                    IF NOT pk_grid.update_grid_task(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_episode        => l_grid_task.id_episode,
                                                    common_order_in  => l_grid_task.common_order,
                                                    common_order_nin => FALSE,
                                                    o_error          => l_error_out)
                    THEN
                        RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        IF l_grid_task.id_episode IS NOT NULL
        THEN
            IF l_task_type = pk_alert_constant.g_task_medical_orders
            THEN
                IF NOT pk_grid.update_grid_task(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_episode         => l_grid_task.id_episode,
                                                medical_order_in  => l_grid_task.medical_order,
                                                medical_order_nin => FALSE,
                                                o_error           => l_error_out)
                THEN
                    RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                END IF;
            ELSE
                g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode';
                IF NOT pk_grid.update_grid_task(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_episode        => l_grid_task.id_episode,
                                                common_order_in  => l_grid_task.common_order,
                                                common_order_nin => FALSE,
                                                o_error          => l_error_out)
                THEN
                    RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                END IF;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => g_error);
    END ins_grid_task_epis;

    PROCEDURE get_data_rowid
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_table_name IN VARCHAR,
        i_rowids     IN table_varchar,
        o_rowids     OUT table_varchar
    ) IS
        l_error_out t_error_out;
    BEGIN
    
        IF i_table_name = 'COMM_ORDER_REQ'
        THEN
            o_rowids := i_rowids;
        
        ELSIF i_table_name = 'COMM_ORDER_PLAN'
        THEN
            o_rowids := i_rowids;
        
            SELECT cor.rowid
              BULK COLLECT
              INTO o_rowids
              FROM comm_order_plan cop
             INNER JOIN comm_order_req cor
                ON cor.id_comm_order_req = cop.id_comm_order_req
             WHERE cop.rowid IN (SELECT column_value
                                   FROM TABLE(i_rowids));
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DATA_ROWID',
                                              l_error_out);
        
            o_rowids := table_varchar();
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_data_rowid;

/********************************************************************************************/
/********************************************************************************************/
/********************************************************************************************/

BEGIN
    -- log initialization
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(object_name => g_package_name);
    g_debug := pk_alertlog.is_debug_enabled(i_object_name => g_package_name);
END pk_ea_logic_comm_orders;
/
