/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_not_order_reason IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    FUNCTION get_concept_type_list_ids RETURN table_number IS
        l_func_name CONSTANT t_low_char := 'GET_CONCEPT_TYPE_LIST_IDS';
    
        l_ret   table_number;
        l_error t_error_out;
    BEGIN
        g_error := 'get concept types lists of ids';
        pk_alertlog.log_debug(g_error, g_package, l_func_name);
    
        SELECT ct.id_concept_type
          BULK COLLECT
          INTO l_ret
          FROM concept_type ct
         WHERE ct.internal_name IN (SELECT column_value
                                      FROM TABLE(k_concept_type_list));
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => k_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
        
            RETURN NULL;
    END get_concept_type_list_ids;

    PROCEDURE populate_ea(i_inst IN institution.id_institution%TYPE) IS
        l_func_name CONSTANT t_low_char := 'POPULATE_EA';
    
        CURSOR s_cur(l_inst IN t_big_num) IS
            SELECT id_not_order_reason_ea,
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
                   code_concept_type_name
              FROM (SELECT (SELECT ora_hash(lpad(mct.id_concept_term, 24, 0) || lpad(mct.id_cncpt_trm_inst_owner, 24, 0) ||
                                            lpad(mct.id_concept_version, 24, 0) ||
                                            lpad(mct.id_cncpt_vrs_inst_owner, 24, 0) || lpad(cttt.id_task_type, 24, 0))
                              FROM dual) id_not_order_reason_ea,
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
                           ctr.id_concept_type          id_concept_type,
                           ctype.code_concept_type_name
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
                                    WHERE int_mct.id_institution = l_inst
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
                       AND mtv.id_task_type = cttt.id_task_type
                       AND cttt.id_task_type IN (SELECT /*+ opt_estimate (table t rows=8)*/
                                                  column_value
                                                   FROM TABLE(k_task_type_list) t)
                       AND mcva.flg_active = k_yes
                       AND ctr.id_concept_type IN (SELECT column_value
                                                     FROM TABLE(get_concept_type_list_ids) t)
                          -- The concept term must have a preferred term
                       AND EXISTS (SELECT 1
                              FROM concept_term ct1
                              JOIN concept_term_type ctt1
                                ON ctt1.id_concept_term_type = ct1.id_concept_term_type
                             WHERE ct1.id_concept_vers_start = cv.id_concept_version
                               AND ct1.id_concept_vers_end = cv.id_concept_version
                               AND ct1.flg_available = k_yes
                               AND ctt1.internal_name = k_pref_term_str)
                       AND mtv.id_institution = l_inst) ttt;
    
        TYPE fetch_array IS TABLE OF s_cur%ROWTYPE;
        s_array fetch_array;
    
    BEGIN
        g_error := 'open r_inst cursor';
        pk_alertlog.log_debug(g_error, g_package, l_func_name);
        FOR r_inst IN (SELECT *
                         FROM (SELECT DISTINCT id_institution
                                 FROM visit v
                                WHERE id_institution NOT IN (-1, 0)
                                ORDER BY 1) t
                        WHERE t.id_institution = i_inst
                           OR i_inst = 0)
        LOOP
            g_error := 'delete not_order_reason_ea->inst=' || r_inst.id_institution;
            pk_alertlog.log_debug(g_error, g_package, l_func_name);
            DELETE FROM not_order_reason_ea norea
             WHERE norea.id_institution_term_vers = i_inst;
        
            g_error := 'open s_cur->inst=' || r_inst.id_institution;
            pk_alertlog.log_debug(g_error, g_package, l_func_name);
        
            OPEN s_cur(r_inst.id_institution);
            LOOP
                FETCH s_cur BULK COLLECT
                    INTO s_array;
            
                FORALL i IN 1 .. s_array.count
                    INSERT INTO not_order_reason_ea
                        (id_not_order_reason_ea,
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
                         code_concept_type_name)
                    VALUES
                        (s_array(i).id_not_order_reason_ea,
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
                         s_array(i).code_concept_type_name);
            
                dbms_output.put_line('Institution ' || lpad(r_inst.id_institution, 10, 0) || ' -> ' || SQL%ROWCOUNT ||
                                     ' records inserted -> ' || current_timestamp);
            
                COMMIT;
            
                EXIT WHEN s_cur%NOTFOUND;
            END LOOP;
            CLOSE s_cur;
        END LOOP;
    
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(SQLERRM);
            ROLLBACK;
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package, sub_object_name => l_func_name);
    END populate_ea;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_ea_logic_not_order_reason;
/
