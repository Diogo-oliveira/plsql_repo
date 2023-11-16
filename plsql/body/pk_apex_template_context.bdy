/*-- Last Change Revision: $Rev: 1920261 $*/
/*-- Last Change by: $Author: luis.fernandes $*/
/*-- Date of last change: $Date: 2019-10-11 15:45:30 +0100 (sex, 11 out 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_apex_template_context IS

    g_error         VARCHAR(2000);
    g_package_name  VARCHAR2(200);
    g_package_owner VARCHAR2(200);
    g_func_name     VARCHAR2(200);

    /********************************************************************************************
    * Checks if there is a null value in collection 
    *
    * @param i_table                Collection
    *
    * @result                      1 if true, 0 if false
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/
    FUNCTION is_null_in_collection(i_table IN table_number) RETURN NUMBER IS
    BEGIN
        FOR i IN 1 .. i_table.count
        LOOP
            IF i_table(i) IS NULL
            THEN
                RETURN 1;
            END IF;
        
        END LOOP;
        RETURN 0;
    END is_null_in_collection;

    /********************************************************************************************
    * Get doc_template_context contexts based on flag type 
    *
    * @param i_flg_type           Flag type
    * @param i_dep_clin_serv      Dep_clin_servs
    * @param i_complaint          Complaints
    * @param i_doc_area           Doc_areas
    * @param i_exam               Exams
    * @param i_intervention       Interventions
    * @param i_rehab              Rehabs
    * @param i_sp                 Surgical procedures
    * @param o_context            Return for id_context
    * @param o_context_2          Return for id_context 2
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/
    PROCEDURE get_dtc_contexts
    (
        i_flg_type      IN doc_template_context.flg_type%TYPE,
        i_dep_clin_serv IN VARCHAR2,
        i_complaint     IN VARCHAR2,
        i_doc_area      IN VARCHAR2,
        i_exam          IN VARCHAR2,
        i_intervention  IN VARCHAR2,
        i_rehab         IN VARCHAR2,
        i_sp            IN VARCHAR2,
        o_context       OUT VARCHAR2,
        o_context_2     OUT VARCHAR2
    ) IS
    BEGIN
        SELECT decode(i_flg_type,
                      'A',
                      i_dep_clin_serv,
                      'C',
                      i_complaint,
                      'D',
                      i_doc_area,
                      'DC',
                      i_doc_area,
                      'E',
                      i_exam,
                      'ER',
                      i_exam,
                      'I',
                      i_intervention,
                      'P',
                      '-1',
                      'S',
                      i_dep_clin_serv,
                      'CT',
                      i_complaint,
                      'DA',
                      i_doc_area,
                      'DS',
                      i_doc_area,
                      'SP',
                      i_doc_area,
                      'R',
                      i_rehab)
        
          INTO o_context
          FROM dual;
    
        SELECT decode(i_flg_type, 'SP', i_sp, 'DC', i_complaint)
          INTO o_context_2
          FROM dual;
    
    END get_dtc_contexts;

    /********************************************************************************************
    * Get doc_template_context ids for given filters
    *
    * @param i_institution              Institution id
    * @param i_softwares                Softwares id array
    * @param i_profile_templates        Profile templates array
    * @param i_doc_templates            Doc templates array
    * @param i_dep_clin_serv            Dep clin serv array
    * @param i_flg_type                 Flag type
    * @param i_context1                 id_context 1
    * @param i_context2                 id_context 2
    
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/
    FUNCTION get_dtc_ids
    (
        i_institution       IN institution.id_institution%TYPE,
        i_softwares         IN table_number,
        i_profile_templates IN table_number,
        i_doc_templates     IN table_number,
        i_dep_clin_serv     IN table_number,
        i_flg_type          IN doc_template_context.flg_type%TYPE,
        i_context1          IN table_number,
        i_context2          IN table_number
    ) RETURN table_number IS
        l_ids                     table_number;
        l_softwares_final         table_number;
        l_profile_templates_final table_number;
        l_doc_templates_final     table_number;
        l_dep_clin_serv_final     table_number;
        l_context1_final          table_number;
        l_context2_final          table_number;
    BEGIN
        IF i_softwares.count = 0
        THEN
            l_softwares_final := NULL;
        ELSE
            l_softwares_final := i_softwares;
            l_softwares_final.extend;
            l_softwares_final(l_softwares_final.count) := 0;
        
        END IF;
    
        IF i_profile_templates.count = 0
        THEN
            l_profile_templates_final := NULL;
        ELSE
            l_profile_templates_final := i_profile_templates;
        
        END IF;
    
        IF i_doc_templates.count = 0
        THEN
            l_doc_templates_final := NULL;
        ELSE
            l_doc_templates_final := i_doc_templates;
        
        END IF;
    
        IF i_dep_clin_serv.count = 0
        THEN
            l_dep_clin_serv_final := NULL;
        ELSE
            l_dep_clin_serv_final := i_dep_clin_serv;
        
        END IF;
    
        IF i_context1.count = 0
        THEN
            l_context1_final := NULL;
        ELSE
            l_context1_final := i_context1;
        
        END IF;
    
        IF i_context2.count = 0
        THEN
            l_context2_final := NULL;
        ELSE
            l_context2_final := i_context2;
        
        END IF;
    
        SELECT "ID_DOC_TEMPLATE_CONTEXT"
          BULK COLLECT
          INTO l_ids
          FROM doc_template_context
         WHERE id_institution IN (0, i_institution)
           AND (id_software IN (SELECT column_value
                                  FROM TABLE(l_softwares_final)) OR l_softwares_final IS NULL)
           AND (id_profile_template IN (SELECT column_value
                                          FROM TABLE(l_profile_templates_final)) OR l_profile_templates_final IS NULL OR
               /*(*/
               id_profile_template IS NULL /*AND is_null_in_collection(l_profile_templates_final) = 1)*/
               )
           AND (id_doc_template IN (SELECT column_value
                                      FROM TABLE(l_doc_templates_final)) OR l_doc_templates_final IS NULL OR
               (id_doc_template IS NULL AND is_null_in_collection(l_doc_templates_final) = 1))
           AND ((flg_type NOT IN ('ER', 'DC', 'C', 'SP', 'D', 'I', 'R', 'P') AND
               id_dep_clin_serv IN (SELECT column_value
                                        FROM TABLE(l_dep_clin_serv_final))) OR l_dep_clin_serv_final IS NULL OR
               (id_dep_clin_serv IS NULL AND is_null_in_collection(l_dep_clin_serv_final) = 1) OR
               flg_type IN ('ER', 'DC', 'C', 'SP', 'D', 'I', 'R', 'P'))
           AND (flg_type = i_flg_type OR i_flg_type IS NULL)
           AND ((flg_type NOT IN ('A', 'S') AND
               id_context IN (SELECT column_value
                                  FROM TABLE(l_context1_final))) OR l_context1_final IS NULL OR flg_type IN ('A', 'S'))
           AND ((flg_type NOT IN ('DA', 'DS') AND
               id_context_2 IN (SELECT column_value
                                    FROM TABLE(l_context2_final))) OR l_context2_final IS NULL OR
               flg_type NOT IN ('DA', 'DS'));
    
        RETURN l_ids;
    END get_dtc_ids;

    /********************************************************************************************
    * Clones doc_template_context records from a facility to another,
    * allowing software specification
    * The origin and destination facility can be the same (to clone configurations from a software to another) 
    *
    * @param i_lang                Log Language ID
    * @param i_destination_inst    Destination facility
    * @param i_destination_soft    Destination software
    * @param i_dtc                 Doc template context id array
    * @param o_error               Error output   
    *
    * @result                      true if successful
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/
    FUNCTION clone_dtc_to_inst
    (
        i_lang             IN language.id_language%TYPE,
        i_destination_inst IN institution.id_institution%TYPE,
        i_destination_soft IN software.id_software%TYPE,
        i_dtc              IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        INSERT INTO doc_template_context
            (id_doc_template_context,
             id_doc_template,
             id_institution,
             id_software,
             id_profile_template,
             id_dep_clin_serv,
             adw_last_update,
             id_context,
             flg_type,
             id_sch_event,
             id_context_2)
            SELECT seq_doc_template_context.nextval,
                   id_doc_template,
                   id_institution,
                   id_software,
                   id_profile_template,
                   id_dep_clin_serv,
                   SYSDATE,
                   id_context,
                   flg_type,
                   id_sch_event,
                   id_context_2
              FROM (SELECT id_doc_template,
                           i_destination_inst id_institution,
                           nvl(i_destination_soft, id_software) id_software,
                           id_context,
                           id_context_2,
                           id_profile_template,
                           id_dep_clin_serv,
                           id_sch_event,
                           flg_type,
                           row_number() over(PARTITION BY id_doc_template, id_institution, nvl(i_destination_soft, id_software), id_context, id_context_2, id_profile_template, id_dep_clin_serv, id_sch_event, flg_type ORDER BY rownum) records_count
                      FROM doc_template_context dtc
                     WHERE dtc.id_doc_template_context IN (SELECT column_value
                                                             FROM TABLE(i_dtc))) res
             WHERE NOT EXISTS (SELECT 0
                      FROM doc_template_context dtc_1
                     WHERE dtc_1.id_institution = i_destination_inst
                       AND dtc_1.id_doc_template = res.id_doc_template
                       AND dtc_1.id_software = res.id_software
                       AND dtc_1.id_context = res.id_context
                       AND dtc_1.id_context_2 = res.id_context_2
                       AND dtc_1.id_profile_template = res.id_profile_template
                       AND dtc_1.id_dep_clin_serv = res.id_dep_clin_serv
                       AND dtc_1.id_sch_event = res.id_sch_event
                       AND dtc_1.flg_type = res.flg_type)
               AND records_count = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              g_error,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END clone_dtc_to_inst;

    /********************************************************************************************
    * Insert multiple records in doc_template_context using selected filters
    *
    * @param i_lang              Language id
    * @param i_id_doc_template   Doc templates
    * @param i_id_institution    id_institution
    * @param i_id_software       Softwares
    * @param i_id_profile        Profile templates
    * @param i_id_context        id_contexts 
    * @param i_id_dep_clin_serv  id_dep_clin_servs
    * @param i_flg_type          Flag type 
    * @param i_sch_event         Sch_event
    * @param i_id_context_2      Id contexts 2
    * @param o_error             Error output
    *
    * @result                      true if successful
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/
    FUNCTION set_template_context
    (
        i_lang             IN language.id_language%TYPE,
        i_id_doc_template  VARCHAR2,
        i_id_institution   VARCHAR2,
        i_id_software      VARCHAR2,
        i_id_profile       VARCHAR2 DEFAULT NULL,
        i_id_context       VARCHAR2,
        i_id_dep_clin_serv VARCHAR2 DEFAULT NULL,
        i_flg_type         VARCHAR2,
        i_sch_event        VARCHAR2 DEFAULT NULL,
        i_id_context_2     VARCHAR2 DEFAULT NULL,
        o_error            OUT t_error_out
        
    ) RETURN BOOLEAN IS
        l_id_institution      table_number;
        l_id_software         table_number;
        l_id_profile_template table_number;
        l_id_context          table_number;
        l_id_dep_clin_serv    table_number;
        l_sch_event           table_number;
        l_id_context_2        table_number;
        l_exception EXCEPTION;
        l_id_doc_template table_number;
    
    BEGIN
    
        l_id_institution := pk_utils.str_split_n(i_id_institution, ':');
    
        l_id_doc_template := pk_utils.str_split_n(i_id_doc_template, ':');
    
        l_id_software := pk_utils.str_split_n(i_id_software, ':');
    
        IF length(i_id_profile) > 0
        THEN
            l_id_profile_template := pk_utils.str_split_n(i_id_profile, ':');
        ELSE
            l_id_profile_template := NULL;
        END IF;
    
        l_id_context := pk_utils.str_split_n(i_id_context, ':');
    
        IF length(i_id_dep_clin_serv) > 0
        THEN
            l_id_dep_clin_serv := pk_utils.str_split_n(i_id_dep_clin_serv, ':');
        ELSE
            l_id_dep_clin_serv := NULL;
        END IF;
    
        IF length(i_sch_event) > 0
        THEN
            l_sch_event := pk_utils.str_split_n(i_sch_event, ':');
        ELSE
            l_sch_event := NULL;
        END IF;
        IF length(i_id_context_2) > 0
        THEN
            l_id_context_2 := pk_utils.str_split_n(i_id_context_2, ':');
        ELSE
            l_id_context_2 := NULL;
        
        END IF;
    
        INSERT /*+ IGNORE_ROW_ON_DUPKEY_INDEX(doc_template_context DOC_TEMPL_CONT_FK_UNI )*/
        INTO doc_template_context
            (id_doc_template_context,
             id_doc_template,
             id_software,
             id_profile_template,
             id_dep_clin_serv,
             id_context,
             flg_type,
             id_sch_event,
             id_institution,
             id_context_2)
            SELECT seq_doc_template_context.nextval,
                   id_doc_template,
                   id_software,
                   id_profile_template,
                   id_dep_clin_serv,
                   id_context,
                   i_flg_type,
                   id_sch_event,
                   id_institution,
                   id_context_2
              FROM (SELECT DISTINCT c_data.id_doc_template,
                                    c_data.id_software,
                                    c_data.id_profile_template,
                                    decode(i_flg_type,
                                           'ER',
                                           NULL,
                                           'DC',
                                           NULL,
                                           'C',
                                           NULL,
                                           'SP',
                                           NULL,
                                           'D',
                                           NULL,
                                           'I',
                                           NULL,
                                           'R',
                                           NULL,
                                           'P',
                                           NULL,
                                           c_data.id_dep_clin_serv) id_dep_clin_serv,
                                    decode(i_flg_type,
                                           'A',
                                           (SELECT cs.id_clinical_service
                                              FROM clinical_service cs
                                             INNER JOIN dep_clin_serv dcs
                                                ON cs.id_clinical_service = dcs.id_clinical_service
                                             WHERE dcs.id_dep_clin_serv = c_data.id_dep_clin_serv),
                                           'S',
                                           (SELECT cs.id_clinical_service
                                              FROM clinical_service cs
                                             INNER JOIN dep_clin_serv dcs
                                                ON cs.id_clinical_service = dcs.id_clinical_service
                                             WHERE dcs.id_dep_clin_serv = c_data.id_dep_clin_serv),
                                           c_data.id_context) id_context,
                                    i_flg_type,
                                    c_data.id_sch_event,
                                    c_data.id_institution,
                                    decode(i_flg_type,
                                           'DA',
                                           (SELECT cs.id_clinical_service
                                              FROM clinical_service cs
                                             INNER JOIN dep_clin_serv dcs
                                                ON cs.id_clinical_service = dcs.id_clinical_service
                                             WHERE dcs.id_dep_clin_serv = c_data.id_dep_clin_serv),
                                           'DS',
                                           (SELECT cs.id_clinical_service
                                              FROM clinical_service cs
                                             INNER JOIN dep_clin_serv dcs
                                                ON cs.id_clinical_service = dcs.id_clinical_service
                                             WHERE dcs.id_dep_clin_serv = c_data.id_dep_clin_serv),
                                           c_data.id_context_2) id_context_2
                      FROM (SELECT *
                              FROM (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value AS id_institution
                                      FROM TABLE(CAST(l_id_institution AS table_number)) p) t_id_institution,
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value AS id_doc_template
                                      FROM TABLE(CAST(l_id_doc_template AS table_number)) p) t_doc_template,
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value AS id_software
                                      FROM TABLE(CAST(l_id_software AS table_number)) p) t_soft,
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value AS id_profile_template
                                      FROM TABLE(CAST(l_id_profile_template AS table_number)) p
                                    UNION
                                    SELECT NULL AS id_profile_template
                                      FROM dual) t_prof,
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value AS id_dep_clin_serv
                                      FROM TABLE(CAST(l_id_dep_clin_serv AS table_number)) p
                                    UNION
                                    SELECT NULL AS id_dep_clin_serv
                                      FROM dual) t_id_dep_clin_serv,
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value AS id_context
                                      FROM TABLE(CAST(l_id_context AS table_number))) t_context,
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value AS id_context_2
                                      FROM TABLE(CAST(l_id_context_2 AS table_number)) p
                                    UNION
                                    SELECT NULL AS id_context_2
                                      FROM dual) t_context_2,
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value AS id_sch_event
                                      FROM TABLE(CAST(l_sch_event AS table_number)) p
                                    UNION
                                    SELECT NULL AS id_sch_event
                                      FROM dual) t_sch_event) c_data
                     WHERE c_data.id_context IS NOT NULL
                       AND c_data.id_institution IS NOT NULL
                       AND c_data.id_software IS NOT NULL
                       AND c_data.id_doc_template IS NOT NULL
                       AND ((l_id_dep_clin_serv IS NULL AND c_data.id_dep_clin_serv IS NULL) OR
                           (l_id_dep_clin_serv IS NOT NULL AND c_data.id_dep_clin_serv IS NOT NULL))
                          
                       AND ((l_id_profile_template IS NULL AND c_data.id_profile_template IS NULL) OR
                           (l_id_profile_template IS NOT NULL AND c_data.id_profile_template IS NOT NULL))
                          
                       AND ((l_id_context_2 IS NULL AND c_data.id_context_2 IS NULL) OR
                           (l_id_context_2 IS NOT NULL AND c_data.id_context_2 IS NOT NULL))
                          
                       AND ((l_sch_event IS NULL AND c_data.id_sch_event IS NULL) OR
                           (l_sch_event IS NOT NULL AND c_data.id_sch_event IS NOT NULL)))
             WHERE id_context IS NOT NULL
               AND id_institution IS NOT NULL
               AND id_software IS NOT NULL
               AND id_doc_template IS NOT NULL;
    
        IF (l_id_dep_clin_serv IS NOT NULL AND l_id_dep_clin_serv.count != 0)
        THEN
            DELETE FROM doc_template_context a
             WHERE ROWID IN (SELECT ROWID
                               FROM doc_template_context dtc
                              WHERE dtc.id_dep_clin_serv IS NOT NULL
                                AND dtc.flg_type = 'S'
                                AND EXISTS (SELECT 1
                                       FROM dep_clin_serv dcs
                                      WHERE dcs.id_dep_clin_serv = dtc.id_dep_clin_serv
                                        AND dcs.id_clinical_service != dtc.id_context));
        
            DELETE FROM doc_template_context a
             WHERE ROWID IN (SELECT ROWID
                               FROM doc_template_context dtc
                              WHERE dtc.id_dep_clin_serv IS NOT NULL
                                AND dtc.flg_type = 'DS'
                                AND EXISTS (SELECT 1
                                       FROM dep_clin_serv dcs
                                      WHERE dcs.id_dep_clin_serv = dtc.id_dep_clin_serv
                                        AND dcs.id_clinical_service != dtc.id_context_2));
        
            DELETE FROM doc_template_context a
             WHERE ROWID IN (SELECT ROWID
                               FROM doc_template_context dtc
                              WHERE dtc.id_dep_clin_serv IS NOT NULL
                                AND dtc.flg_type = 'DA'
                                AND EXISTS (SELECT 1
                                       FROM dep_clin_serv dcs
                                      WHERE dcs.id_dep_clin_serv = dtc.id_dep_clin_serv
                                        AND dcs.id_clinical_service != dtc.id_context_2));
        
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
    END;

    /********************************************************************************************
    * Delete doc_template_context records
    *
    * @param i_lang              Language id
    * @param id_dtc_array        Doc template context id array
    * @param o_error             Error output
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/
    FUNCTION del_multiple_values_dtc
    (
        i_lang       IN language.id_language%TYPE,
        id_dtc_array IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_func_name := 'del_multiple_values_dtc';
    
        DELETE FROM doc_template_context dtc
         WHERE dtc.id_doc_template_context IN
               (SELECT column_value
                  FROM TABLE(CAST(id_dtc_array AS table_number)));
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              g_error,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END del_multiple_values_dtc;

    /********************************************************************************************
    * Clones doc_area_soft_inst records from a facility to another,
    * allowing software specification
    * The origin and destination facility can be the same (to clone configurations from a software to another) 
    *
    * @param i_lang                Log Language ID
    * @param i_destination_inst    Destination facility
    * @param i_destination_soft    Destination software
    * @param i_dais                Doc_area_inst_soft id array
    * @param o_error               Error output   
    *
    * @result                      true if successful
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/
    FUNCTION clone_dais_to_inst
    (
        i_lang             IN language.id_language%TYPE,
        i_destination_inst IN institution.id_institution%TYPE,
        i_destination_soft IN software.id_software%TYPE,
        i_dais             IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    BEGIN
    
        INSERT INTO doc_area_inst_soft
            (id_doc_area_inst_soft,
             id_doc_area,
             id_institution,
             id_software,
             flg_mode,
             adw_last_update,
             flg_switch_mode,
             flg_type,
             flg_multiple,
             id_sys_shortcut_error,
             flg_scope_type,
             flg_data_paging_enabled,
             page_size,
             id_market)
            SELECT seq_doc_area_inst_soft.nextval,
                   id_doc_area,
                   id_institution,
                   id_software,
                   flg_mode,
                   SYSDATE,
                   flg_switch_mode,
                   flg_type,
                   flg_multiple,
                   id_sys_shortcut_error,
                   flg_scope_type,
                   flg_data_paging_enabled,
                   page_size,
                   NULL
              FROM (SELECT id_doc_area,
                           i_destination_inst id_institution,
                           nvl(i_destination_soft, id_software) id_software,
                           flg_mode,
                           flg_switch_mode,
                           flg_type,
                           flg_multiple,
                           id_sys_shortcut_error,
                           flg_scope_type,
                           flg_data_paging_enabled,
                           page_size,
                           id_market,
                           row_number() over(PARTITION BY id_doc_area, id_institution, nvl(i_destination_soft, id_software), id_market ORDER BY id_institution DESC, id_market DESC, id_software DESC) records_count
                      FROM doc_area_inst_soft dais
                     WHERE dais.id_doc_area_inst_soft IN (SELECT column_value
                                                            FROM TABLE(i_dais))) res
             WHERE NOT EXISTS (SELECT 0
                      FROM doc_area_inst_soft dais_1
                     WHERE dais_1.id_institution = i_destination_inst
                       AND dais_1.id_doc_area = res.id_doc_area
                       AND dais_1.id_software = res.id_software
                       AND dais_1.id_market IS NULL
                       AND res.id_market IS NULL)
               AND records_count = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              g_error,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END clone_dais_to_inst;

    /********************************************************************************************
    * Delete doc_area_inst_soft records
    *
    * @param i_lang                Log Language ID
    * @param i_destination_inst    Destination facility
    * @param i_dais                Doc_area_inst_soft id array
    * @param o_error               Error output   
    *
    * @result                      true if successful
    *
    * @author                      LFSF
    * @version                     2.8.0.1
    * @since                       2019/10/11
    ********************************************************************************************/
    FUNCTION del_multiple_dais
    (
        i_lang             IN language.id_language%TYPE,
        i_destination_inst IN institution.id_institution%TYPE,
        i_dais             IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_instit NUMBER;
        l_market NUMBER;
    
    BEGIN
    
        FOR i IN (SELECT column_value AS l_id_doc_area_inst_soft
                    FROM TABLE(i_dais))
        LOOP
        
            SELECT id_institution, id_market
              INTO l_instit, l_market
              FROM doc_area_inst_soft
             WHERE id_doc_area_inst_soft = i.l_id_doc_area_inst_soft;
        
            IF l_instit = 0
            THEN
            
                IF l_market != 0
                THEN
                
                    INSERT INTO doc_area_inst_soft
                        SELECT seq_doc_area_inst_soft.nextval,
                               id_doc_area,
                               tmp.id_institution,
                               id_software,
                               flg_mode,
                               adw_last_update,
                               flg_switch_mode,
                               flg_type,
                               flg_multiple,
                               id_sys_shortcut_error,
                               create_user,
                               create_time,
                               create_institution,
                               update_user,
                               update_time,
                               update_institution,
                               flg_scope_type,
                               flg_data_paging_enabled,
                               page_size,
                               NULL AS id_market
                          FROM doc_area_inst_soft dais
                         CROSS JOIN (SELECT id_institution
                                       FROM alert.institution
                                      WHERE flg_available = 'Y'
                                        AND id_market = l_market
                                        AND id_institution != i_destination_inst) tmp
                         WHERE dais.id_doc_area_inst_soft = i.l_id_doc_area_inst_soft;
                
                ELSE
                
                    INSERT INTO doc_area_inst_soft
                        SELECT seq_doc_area_inst_soft.nextval,
                               id_doc_area,
                               tmp.id_institution,
                               id_software,
                               flg_mode,
                               adw_last_update,
                               flg_switch_mode,
                               flg_type,
                               flg_multiple,
                               id_sys_shortcut_error,
                               create_user,
                               create_time,
                               create_institution,
                               update_user,
                               update_time,
                               update_institution,
                               flg_scope_type,
                               flg_data_paging_enabled,
                               page_size,
                               NULL AS id_market
                          FROM doc_area_inst_soft dais
                         CROSS JOIN (SELECT id_institution
                                       FROM alert.institution
                                      WHERE flg_available = 'Y'
                                        AND id_institution != i_destination_inst) tmp
                         WHERE dais.id_doc_area_inst_soft = i.l_id_doc_area_inst_soft;
                
                END IF;
            
            END IF;
        
            DELETE FROM doc_area_inst_soft dais
             WHERE dais.id_doc_area_inst_soft = i.l_id_doc_area_inst_soft;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              g_error,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END del_multiple_dais;

    /********************************************************************************************
    * Get doc_area_inst_soft ids for given filters
    *
    * @param i_institution              Institution id
    * @param i_softwares                Softwares id array
    * @param i_doc_areas                Doc area id array
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/
    FUNCTION get_dais_ids
    (
        i_institution institution.id_institution%TYPE,
        i_softwares   table_number,
        i_doc_areas   table_number
    ) RETURN table_number IS
        l_ids             table_number;
        l_softwares_final table_number;
        l_doc_areas_final table_number;
        l_inst_mkt        market.id_market%TYPE := pk_utils.get_institution_market(1, i_institution);
    BEGIN
    
        IF i_softwares.count = 0
        THEN
            l_softwares_final := NULL;
        ELSE
            l_softwares_final := i_softwares;
            l_softwares_final.extend;
            l_softwares_final(l_softwares_final.count) := 0;
        
        END IF;
        IF i_doc_areas.count = 0
        THEN
            l_doc_areas_final := NULL;
        ELSE
            l_doc_areas_final := i_doc_areas;
        
        END IF;
        SELECT id_doc_area_inst_soft
          BULK COLLECT
          INTO l_ids
          FROM doc_area_inst_soft
         WHERE id_institution IN (0, i_institution)
           AND (id_market IN (0, l_inst_mkt) OR id_market IS NULL)
           AND (id_software IN (SELECT column_value
                                  FROM TABLE(l_softwares_final)) OR l_softwares_final IS NULL)
           AND (id_doc_area IN (SELECT column_value
                                  FROM TABLE(l_doc_areas_final)) OR l_doc_areas_final IS NULL);
    
        RETURN l_ids;
    
    END get_dais_ids;

    /********************************************************************************************
    * Delete doc_area_inst_soft records
    *
    * @param i_lang              Language id
    * @param id_dais_array       doc_area_inst_soft id array
    * @param o_error             Error output
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/
    FUNCTION del_multiple_values_dais
    (
        i_lang        IN language.id_language%TYPE,
        id_dais_array IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_func_name := 'del_multiple_values_dais';
    
        DELETE FROM doc_area_inst_soft dais
         WHERE dais.id_doc_area_inst_soft IN
               (SELECT column_value
                  FROM TABLE(CAST(id_dais_array AS table_number)));
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              g_error,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END del_multiple_values_dais;

    /********************************************************************************************
    * Insert multiple records in doc_area_inst_soft using selected filters
    *
    * @param i_lang                  Language id
    * @param i_institution           Institution id 
    * @param i_software_list         Software id array
    * @param i_doc_area_array        Doc area id array
    * @param i_flg_mode              Flag mode
    * @param i_flg_switch_mode       Flag switch mode
    * @param i_flg_type              Flag type
    * @param i_flg_multiple          Flag multiple
    * @param i_sys_shortcut_error    Sys_shortcut_error id
    * @param i_flg_scope_type        Flag scope type
    * @param i_flg_data_paging_en    Flag data paging
    * @param i_page_size             Page size
    * @param i_market                Market id
    * @param o_error                 Error output
    *
    * @result                        true if successful
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/
    FUNCTION insert_multiple_values_dais
    (
        i_lang               IN language.id_language%TYPE,
        i_institution        IN institution.id_institution%TYPE,
        i_software_list      IN table_number,
        i_doc_area_array     IN table_number,
        i_flg_mode           IN doc_area_inst_soft.flg_mode%TYPE,
        i_flg_switch_mode    IN doc_area_inst_soft.flg_switch_mode%TYPE,
        i_flg_type           IN doc_area_inst_soft.flg_type%TYPE,
        i_flg_multiple       IN doc_area_inst_soft.flg_multiple%TYPE,
        i_sys_shortcut_error IN doc_area_inst_soft.id_sys_shortcut_error%TYPE,
        i_flg_scope_type     IN doc_area_inst_soft.flg_scope_type%TYPE,
        i_flg_data_paging_en IN doc_area_inst_soft.flg_data_paging_enabled%TYPE,
        i_page_size          IN doc_area_inst_soft.page_size%TYPE,
        --  i_market             IN doc_area_inst_soft.id_market%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_func_name := upper('insert_multiple_values_dais');
    
        INSERT INTO doc_area_inst_soft
            (id_doc_area_inst_soft,
             id_doc_area,
             id_institution,
             id_software,
             flg_mode,
             adw_last_update,
             flg_switch_mode,
             flg_type,
             flg_multiple,
             id_sys_shortcut_error,
             flg_scope_type,
             flg_data_paging_enabled,
             page_size,
             id_market)
            SELECT seq_doc_area_inst_soft.nextval,
                   base_query.id_doc_area,
                   i_institution id_institution,
                   base_query.id_software,
                   i_flg_mode,
                   SYSDATE,
                   i_flg_switch_mode,
                   i_flg_type,
                   i_flg_multiple,
                   i_sys_shortcut_error,
                   i_flg_scope_type,
                   i_flg_data_paging_en,
                   i_page_size,
                   NULL
              FROM (SELECT software.column_value id_software, doc_area.column_value id_doc_area
                      FROM TABLE(CAST(i_software_list AS table_number)) software
                     CROSS JOIN(TABLE(CAST(i_doc_area_array AS table_number))) doc_area) base_query
             WHERE NOT EXISTS (SELECT 0
                      FROM doc_area_inst_soft dais_1
                     WHERE dais_1.id_doc_area = base_query.id_doc_area
                       AND dais_1.id_software = base_query.id_software
                       AND dais_1.id_institution = i_institution
                       AND dais_1.id_market IS NULL);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              g_error,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END insert_multiple_values_dais;

    /********************************************************************************************
    * Edit doc_area_inst_soft records in bulk, sending editable values for update
    *
    * @param i_lang                Log Language ID   
    * @param id_vssa_array         Selected records array
    * @param i_flg_mode           flg_mode
    * @param o_error               Error output   
    *
    * @result                      true if successful
    *
    * @author                      LCRS 
    * @version                     2.6.4.3
    * @since                       2015/01/22
    ********************************************************************************************/
    FUNCTION edit_multiple_records_dais
    (
        i_lang               IN language.id_language%TYPE,
        i_dais_array         IN table_number,
        i_flg_mode           IN VARCHAR2,
        i_flg_switch_mode    IN VARCHAR2,
        i_flg_type           IN VARCHAR2,
        i_flg_multiple       IN VARCHAR2,
        i_sys_shortcut_error IN VARCHAR2,
        i_flg_scope_type     IN VARCHAR2,
        i_flg_data_paging    IN VARCHAR2,
        i_page_size          IN VARCHAR2,
        i_market             IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_mode_upd           BOOLEAN := alert_apex_tools.pk_apex_common.is_value_to_update(i_flg_mode);
        l_flg_mode               doc_area_inst_soft.flg_mode%TYPE := alert_apex_tools.pk_apex_common.get_value_to_update(i_value            => i_flg_mode,
                                                                                                                         is_value_to_update => l_flg_mode_upd);
        l_flg_switch_mode_upd    BOOLEAN := alert_apex_tools.pk_apex_common.is_value_to_update(i_flg_switch_mode);
        l_flg_switch_mode        doc_area_inst_soft.flg_switch_mode%TYPE := alert_apex_tools.pk_apex_common.get_value_to_update(i_value            => i_flg_switch_mode,
                                                                                                                                is_value_to_update => l_flg_switch_mode_upd);
        l_flg_type_upd           BOOLEAN := alert_apex_tools.pk_apex_common.is_value_to_update(i_flg_type);
        l_flg_type               doc_area_inst_soft.flg_type%TYPE := alert_apex_tools.pk_apex_common.get_value_to_update(i_value            => i_flg_type,
                                                                                                                         is_value_to_update => l_flg_type_upd);
        l_flg_multiple_upd       BOOLEAN := alert_apex_tools.pk_apex_common.is_value_to_update(i_flg_multiple);
        l_flg_multiple           doc_area_inst_soft.flg_multiple%TYPE := alert_apex_tools.pk_apex_common.get_value_to_update(i_value            => i_flg_multiple,
                                                                                                                             is_value_to_update => l_flg_multiple_upd);
        l_sys_shortcut_error_upd BOOLEAN := alert_apex_tools.pk_apex_common.is_value_to_update(i_sys_shortcut_error);
        l_sys_shortcut_error     doc_area_inst_soft.id_sys_shortcut_error%TYPE := alert_apex_tools.pk_apex_common.get_value_to_update(i_value            => i_sys_shortcut_error,
                                                                                                                                      is_value_to_update => l_sys_shortcut_error_upd);
        l_flg_scope_type_upd     BOOLEAN := alert_apex_tools.pk_apex_common.is_value_to_update(i_flg_scope_type);
        l_flg_scope_type         doc_area_inst_soft.flg_scope_type%TYPE := alert_apex_tools.pk_apex_common.get_value_to_update(i_value            => i_flg_scope_type,
                                                                                                                               is_value_to_update => l_flg_scope_type_upd);
        l_flg_data_paging_upd    BOOLEAN := alert_apex_tools.pk_apex_common.is_value_to_update(i_flg_data_paging);
        l_flg_data_paging        doc_area_inst_soft.flg_data_paging_enabled%TYPE := alert_apex_tools.pk_apex_common.get_value_to_update(i_value            => i_flg_data_paging,
                                                                                                                                        is_value_to_update => l_flg_data_paging_upd);
        l_page_size_upd          BOOLEAN := alert_apex_tools.pk_apex_common.is_value_to_update(i_page_size);
        l_page_size              doc_area_inst_soft.page_size%TYPE := alert_apex_tools.pk_apex_common.get_value_to_update(i_value            => i_page_size,
                                                                                                                          is_value_to_update => l_page_size_upd);
        l_market_upd             BOOLEAN := alert_apex_tools.pk_apex_common.is_value_to_update(i_market);
        l_market                 doc_area_inst_soft.id_market%TYPE := alert_apex_tools.pk_apex_common.get_value_to_update(i_value            => i_market,
                                                                                                                          is_value_to_update => l_market_upd);
    
    BEGIN
        FOR i IN 1 .. i_dais_array.count
        LOOP
        
            ts_doc_area_inst_soft.upd(id_doc_area_inst_soft_in    => i_dais_array(i),
                                      flg_mode_in                 => l_flg_mode,
                                      flg_mode_nin                => NOT (l_flg_mode_upd),
                                      flg_switch_mode_in          => l_flg_switch_mode,
                                      flg_switch_mode_nin         => NOT (l_flg_switch_mode_upd),
                                      flg_type_in                 => l_flg_type,
                                      flg_type_nin                => NOT (l_flg_type_upd),
                                      flg_multiple_in             => l_flg_multiple,
                                      flg_multiple_nin            => NOT (l_flg_multiple_upd),
                                      id_sys_shortcut_error_in    => l_sys_shortcut_error,
                                      id_sys_shortcut_error_nin   => NOT (l_sys_shortcut_error_upd),
                                      flg_scope_type_in           => l_flg_scope_type,
                                      flg_scope_type_nin          => NOT (l_flg_scope_type_upd),
                                      flg_data_paging_enabled_in  => l_flg_data_paging,
                                      flg_data_paging_enabled_nin => NOT (l_flg_data_paging_upd),
                                      page_size_in                => l_page_size,
                                      page_size_nin               => NOT (l_page_size_upd),
                                      id_market_in                => l_market,
                                      id_market_nin               => NOT (l_market_upd));
        
        END LOOP;
    
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END edit_multiple_records_dais;

    /********************************************************************************************
    * Get ped_area_soft_inst ids for given filters
    *
    * @param i_institution              Institution id
    * @param i_softwares                Softwares id array
    * @param i_ped_areas                Ped area id array
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/
    FUNCTION get_pasi_ids
    (
        i_institution institution.id_institution%TYPE,
        i_softwares   table_number,
        i_ped_areas   table_number
    ) RETURN table_varchar IS
        l_ids             table_varchar;
        l_softwares_final table_number;
        l_ped_areas_final table_number;
        l_market          market.id_market%TYPE := pk_utils.get_institution_market(1, i_institution);
    BEGIN
    
        IF i_softwares.count = 0
        THEN
            l_softwares_final := NULL;
        ELSE
            l_softwares_final := i_softwares;
            l_softwares_final.extend;
            l_softwares_final(l_softwares_final.count) := 0;
        
        END IF;
    
        IF i_ped_areas.count = 0
        THEN
            l_ped_areas_final := NULL;
        ELSE
            l_ped_areas_final := i_ped_areas;
        
        END IF;
    
        SELECT ROWID
          BULK COLLECT
          INTO l_ids
          FROM ped_area_soft_inst
         WHERE id_institution IN (0, i_institution)
           AND id_market IN (0, l_market)
           AND (id_software IN (SELECT column_value
                                  FROM TABLE(l_softwares_final)) OR l_softwares_final IS NULL)
           AND (id_ped_area_add IN (SELECT column_value
                                      FROM TABLE(l_ped_areas_final)) OR l_ped_areas_final IS NULL);
        RETURN l_ids;
    END get_pasi_ids;

    /********************************************************************************************
    * Clones ped_area_soft_inst records from a facility to another,
    * allowing software specification
    * The origin and destination facility can be the same (to clone configurations from a software to another) 
    *
    * @param i_lang                Log Language ID
    * @param i_origin_inst         Origin facility
    * @param i_destination_inst    Destination facility
    * @param i_software            Origin software
    * @param i_destination_soft    Destination software
    * @param i_unit_measure        Unit measure id
    * @param o_error               Error output   
    *
    * @result                      true if successful
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/
    FUNCTION clone_pasi_to_inst
    (
        i_lang             IN language.id_language%TYPE,
        i_destination_inst IN institution.id_institution%TYPE,
        i_destination_soft IN software.id_software%TYPE,
        i_rowid            IN table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    BEGIN
    
        INSERT INTO ped_area_soft_inst
            (id_ped_area_add, id_institution, id_software, id_market, flg_available)
            SELECT id_ped_area_add, id_institution, id_software, id_market, flg_available
              FROM (SELECT id_ped_area_add,
                           i_destination_inst id_institution,
                           nvl(i_destination_soft, id_software) id_software,
                           id_market,
                           flg_available,
                           row_number() over(PARTITION BY id_ped_area_add, id_institution, nvl(i_destination_soft, id_software), id_market ORDER BY id_institution DESC, id_market DESC, id_software DESC) records_count
                      FROM ped_area_soft_inst pasi
                     WHERE pasi.rowid IN (SELECT column_value
                                            FROM TABLE(i_rowid))) res
             WHERE NOT EXISTS (SELECT 0
                      FROM ped_area_soft_inst pasi_1
                     WHERE pasi_1.id_institution = i_destination_inst
                       AND pasi_1.id_ped_area_add = res.id_ped_area_add
                       AND pasi_1.id_software = res.id_software
                       AND pasi_1.id_market = res.id_market)
               AND records_count = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              g_error,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END clone_pasi_to_inst;

    /********************************************************************************************
    * Delete ped_area_soft_inst records
    *
    * @param i_lang              Language id
    * @param id_pasi_array       ped_area_soft_inst id array
    * @param o_error             Error output
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/
    FUNCTION del_multiple_values_pasi
    (
        i_lang        IN language.id_language%TYPE,
        id_pasi_array IN table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_func_name := 'del_multiple_values_pasi';
    
        DELETE FROM ped_area_soft_inst pasi
         WHERE pasi.rowid IN (SELECT column_value
                                FROM TABLE(CAST(id_pasi_array AS table_varchar)));
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              g_error,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END del_multiple_values_pasi;

    /********************************************************************************************
    * Insert multiple records in ped_area_soft_inst using selected filters
    *
    * @param i_lang               Language id
    * @param i_institution        Institution id
    * @param i_software_list      Software id array
    * @param i_ped_area_add_array Ped_area_add id array
    * @param i_market             Market id
    * @param i_flg_available      Flg available
    * @param o_error              Error output
    *
    * @result                     true if successful
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/
    FUNCTION insert_multiple_values_pasi
    (
        i_lang               IN language.id_language%TYPE,
        i_institution        IN institution.id_institution%TYPE,
        i_software_list      IN table_number,
        i_ped_area_add_array IN table_number,
        i_flg_available      IN ped_area_soft_inst.flg_available%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_func_name := upper('insert_multiple_values_pasi');
    
        INSERT INTO ped_area_soft_inst
            (id_ped_area_add, id_institution, id_software, id_market, flg_available)
            SELECT base_query.id_ped_area_add, i_institution id_institution, base_query.id_software, 0, i_flg_available
              FROM (SELECT software.column_value id_software, ped_area_add.column_value id_ped_area_add
                      FROM TABLE(CAST(i_software_list AS table_number)) software
                     CROSS JOIN (SELECT column_value
                                  FROM TABLE(CAST(i_ped_area_add_array AS table_number))) ped_area_add) base_query
             WHERE NOT EXISTS (SELECT 0
                      FROM ped_area_soft_inst pasi_1
                     WHERE pasi_1.id_ped_area_add = base_query.id_ped_area_add
                       AND pasi_1.id_software = base_query.id_software
                       AND pasi_1.id_institution = i_institution
                       AND pasi_1.id_market = 0);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              g_error,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END insert_multiple_values_pasi;

    /********************************************************************************************
    * Edit vital_sign_unit_measure records in bulk, sending editable values for update
    *
    * @param i_lang                Log Language ID   
    * @param id_vsum_array         selected records array
    * @param i_val_min             Val min
    * @param i_val_max             Val max
    * @param i_format_num          Format num
    * @param i_age_min             Age min 
    * @param i_age_max             Age max
    * @param o_error               Error output   
    *
    * @result                      true if successful
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/
    FUNCTION edit_multiple_records_pasi
    (
        i_lang              IN language.id_language%TYPE,
        i_ped_area_array    IN table_number,
        i_institution_array IN table_number,
        i_software_array    IN table_number,
        i_market_array      IN table_number,
        i_rank              IN VARCHAR2,
        i_available         IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rank_upd      BOOLEAN := alert_apex_tools.pk_apex_common.is_value_to_update(i_rank);
        l_rank          ped_area_soft_inst.rank%TYPE := alert_apex_tools.pk_apex_common.get_value_to_update(i_value            => i_rank,
                                                                                                            is_value_to_update => l_rank_upd);
        l_available_upd BOOLEAN := alert_apex_tools.pk_apex_common.is_value_to_update(i_available);
        l_available     ped_area_soft_inst.flg_available%TYPE := alert_apex_tools.pk_apex_common.get_value_to_update(i_value            => i_available,
                                                                                                                     is_value_to_update => l_available_upd);
    
    BEGIN
        FOR i IN 1 .. i_ped_area_array.count
        LOOP
        
            ts_ped_area_soft_inst.upd(id_ped_area_add_in => i_ped_area_array(i),
                                      id_institution_in  => i_institution_array(i),
                                      id_software_in     => i_software_array(i),
                                      id_market_in       => i_market_array(i),
                                      rank_in            => l_rank,
                                      rank_nin           => NOT (l_rank_upd),
                                      flg_available_in   => l_available,
                                      flg_available_nin  => NOT (l_available_upd));
        
        END LOOP;
    
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END edit_multiple_records_pasi;

BEGIN
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_apex_template_context;
/
