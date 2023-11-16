/*-- Last Change Revision: $Rev: 2027233 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:35 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_icnp_util IS

    --------------------------------------------------------------------------------
    -- GLOBAL VARIABLES
    --------------------------------------------------------------------------------

    -- Identifes the owner in the log mechanism
    g_package_owner pk_icnp_type.t_package_owner;

    -- Identifes the package in the log mechanism
    g_package_name pk_icnp_type.t_package_name;

    -- Text that briefly describes the current operation
    g_current_operation pk_icnp_type.t_current_operation;

    --------------------------------------------------------------------------------
    -- METHODS [INIT]
    --------------------------------------------------------------------------------

    /**
     * Executes all the instructions needed to correctly initialize the package.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE initialize IS
    BEGIN
        -- Initializes the log mechanism
        g_current_operation := 'INIT LOG MECHANISM';
        g_package_owner     := 'ALERT';
        g_package_name      := pk_alertlog.who_am_i;
        pk_alertlog.log_init(g_package_name);
    
        -- Log message
        pk_alertlog.log_debug(text => 'initialize()');
    END;

    --------------------------------------------------------------------------------
    -- METHODS
    --------------------------------------------------------------------------------

    /**
     * Throws an unexpected error. This method is used when a function, that returns 
     * a boolean to indicate the success / unsuccess of the call, is invoked and an
     * error occurs. This method was created to centralize the raise of this kind of
     * errors in only one place and because if needed we can add more information from
     * the error details to the exception text.
     * 
     * @param i_method The method where the error occurred.
     * @param i_error The details of the error, like for example: ora_sqlcode and 
     *                ora_sqlerrm.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 28/Jul/2011 (v2.6.1)
    */
    PROCEDURE raise_unexpected_error
    (
        i_method IN VARCHAR2,
        i_error  IN t_error_out
    ) IS
    BEGIN
        pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_unexpected_error,
                                        text_in       => 'An unexpected error occurred while calling the method ' ||
                                                         i_method);
    END;

    /**
     * Checks if a table with numbers is empty. The table is considered empty if it 
     * is null or if it has no records.
     *
     * @param i_table Table that we want to check.
     *
     * @return True when the table is empty; false otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jul/2011 (v2.6.1)
    */
    FUNCTION is_table_empty(i_table IN table_number) RETURN BOOLEAN IS
    BEGIN
        RETURN i_table IS NULL OR i_table IS empty;
    END;

    /**
     * Checks if a table with strings is empty. The table is considered empty if it 
     * is null or if it has no records.
     *
     * @param i_table Table that we want to check.
     *
     * @return True when the table is empty; false otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jul/2011 (v2.6.1)
    */
    FUNCTION is_table_empty(i_table IN table_varchar) RETURN BOOLEAN IS
    BEGIN
        RETURN i_table IS NULL OR i_table IS empty;
    END;

    /**
     * Checks if a table with icnp_epis_intervention records is empty. The table is 
     * considered empty if it is null or if it has no records.
     *
     * @param i_table Table that we want to check.
     *
     * @return True when the table is empty; false otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 15/Jul/2011 (v2.6.1)
    */
    FUNCTION is_table_empty(i_table IN ts_icnp_epis_intervention.icnp_epis_intervention_tc) RETURN BOOLEAN IS
    BEGIN
        RETURN i_table IS NULL OR i_table.count = 0;
    END;

    /**
     * Checks if a table with icnp_interv_plan records is empty. The table is
     * considered empty if it is null or if it has no records.
     *
     * @param i_table Table that we want to check.
     *
     * @return True when the table is empty; false otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 18/Jul/2011 (v2.6.1)
    */
    FUNCTION is_table_empty(i_table IN ts_icnp_interv_plan.icnp_interv_plan_tc) RETURN BOOLEAN IS
    BEGIN
        RETURN i_table IS NULL OR i_table.count = 0;
    END;

    /**
     * Checks if a table with icnp_epis_diagnosis records is empty. The table is
     * considered empty if it is null or if it has no records.
     *
     * @param i_table Table that we want to check.
     *
     * @return True when the table is empty; false otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 18/Jul/2011 (v2.6.1)
    */
    FUNCTION is_table_empty(i_table IN ts_icnp_epis_diagnosis.icnp_epis_diagnosis_tc) RETURN BOOLEAN IS
    BEGIN
        RETURN i_table IS NULL OR i_table.count = 0;
    END;

    /**
     * Checks if a table with icnp_suggest_interv records is empty. The table is
     * considered empty if it is null or if it has no records.
     *
     * @param i_table Table that we want to check.
     *
     * @return True when the table is empty; false otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 18/Jul/2011 (v2.6.1)
    */
    FUNCTION is_table_empty(i_table IN ts_icnp_suggest_interv.icnp_suggest_interv_tc) RETURN BOOLEAN IS
    BEGIN
        RETURN i_table IS NULL OR i_table.count = 0;
    END;

    /**
     * Checks if a table with icnp_epis_diag_interv records is empty. The table is
     * considered empty if it is null or if it has no records.
     *
     * @param i_table Table that we want to check.
     *
     * @return True when the table is empty; false otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 26/Jul/2011 (v2.6.1)
    */
    FUNCTION is_table_empty(i_table IN ts_icnp_epis_diag_interv.icnp_epis_diag_interv_tc) RETURN BOOLEAN IS
    BEGIN
        RETURN i_table IS NULL OR i_table.count = 0;
    END;

    /**
     * Checks if a table with tables of varchars is empty. The table is considered 
     * empty if it is null or if it has no records.
     *
     * @param i_table Table that we want to check.
     *
     * @return True when the table is empty; false otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 25/Jul/2011 (v2.6.1)
    */
    FUNCTION is_table_empty(i_table IN table_table_varchar) RETURN BOOLEAN IS
    BEGIN
        RETURN i_table IS NULL OR i_table.count = 0;
    END;

    /**
     * Checks if a table of records that have all the data needed to correctly execute
     * an intervention is empty. The table is considered empty if it is null or if it
     * has no records.
     *
     * @param i_table Table that we want to check.
     *
     * @return True when the table is empty; false otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 08/Sep/2011 (v2.6.1)
    */
    FUNCTION is_table_empty(i_exec_interv_coll IN pk_icnp_type.t_exec_interv_coll) RETURN BOOLEAN IS
    BEGIN
        RETURN i_exec_interv_coll IS NULL OR i_exec_interv_coll.count = 0;
    END;

    /**
     * Converts a professional object to a string.
     * 
     * @param i_prof The professional context [id user, id institution, id software].
     * 
     * @return A string that represents the professional.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jul/2011 (v2.6.1)
    */
    FUNCTION to_string(i_prof IN profissional) RETURN tlog.ltexte%TYPE IS
    BEGIN
        RETURN '{' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '}';
    END;

    /**
     * Converts a boolean to a string.
     * 
     * @param i_input The boolean value.
     * 
     * @return A string that represents the boolean value.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jul/2011 (v2.6.1)
    */
    FUNCTION to_string(i_input IN BOOLEAN) RETURN VARCHAR2 IS
        l_result VARCHAR2(5 CHAR) := '';
    BEGIN
        IF i_input IS NULL
        THEN
            l_result := 'NULL';
        ELSIF i_input
        THEN
            l_result := 'TRUE';
        ELSE
            l_result := 'FALSE';
        END IF;
    
        RETURN l_result;
    END;

    /**
     * Converts a record that has all the data needed to correctly execute an 
     * intervention to a string.
     * 
     * @param i_exec_interv_rec The record with all the data needed to correctly execute 
     *                          an intervention.
     * 
     * @return A string that represents the data needed to correctly execute an 
     *         intervention.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 08/Sep/2011 (v2.6.1)
    */
    FUNCTION to_string(i_exec_interv_rec IN pk_icnp_type.t_exec_interv_rec) RETURN VARCHAR2 IS
    BEGIN
        RETURN '{id_icnp_epis_interv:' || i_exec_interv_rec.id_icnp_epis_interv || ', id_order_recurr_plan:' || i_exec_interv_rec.id_order_recurr_plan || ', exec_number:' || i_exec_interv_rec.exec_number || '}';
    END;

    /**
     * Converts a collection of records with all the data needed to correctly execute 
     * an intervention to a string.
     * 
     * @param i_exec_interv_coll The collection with all the data needed to correctly 
     *                           execute an intervention.
     * 
     * @return A string that represents the data needed to correctly execute an 
     *         intervention.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 08/Sep/2011 (v2.6.1)
    */
    FUNCTION to_string(i_exec_interv_coll IN pk_icnp_type.t_exec_interv_coll) RETURN VARCHAR2 IS
        l_result VARCHAR2(32767) := '';
    BEGIN
        IF i_exec_interv_coll IS NULL
        THEN
            l_result := 'NULL';
        ELSIF i_exec_interv_coll.count = 0
        THEN
            l_result := 'EMPTY';
        ELSE
            l_result := l_result || '[';
            FOR i IN 1 .. i_exec_interv_coll.count
            LOOP
                l_result := l_result || to_string(i_exec_interv_coll(i)) || '; ';
            END LOOP;
            l_result := l_result || ']';
        END IF;
    
        RETURN l_result;
    END;

    /**
    *Setup ICNP for institutions group
    *
    * @param i_lang   Language ID
    * @param i_inst   Institution ID
    *
    * @return                Return comment 
    * 
    * @author                Nuno Neves
    * @version               Version identification 
    * @since                 2012/06/21
    */
    FUNCTION mig_icnp_inst_group
    (
        i_lang IN language.id_language%TYPE,
        i_inst IN institution.id_institution%TYPE
    ) RETURN BOOLEAN IS
        l_inst              table_number;
        l_flg_rel           VARCHAR2(30) := 'ADT';
        l_composition       table_number;
        l_predefined_action table_number;
        l_error             table_varchar;
        l_new_comp          icnp_composition.id_composition%TYPE;
        l_new_pred_action   icnp_predefined_action.id_predefined_action%TYPE;
        l_table_old         table_number := table_number();
        l_table_new         table_number := table_number();
        l_table_inst        table_number := table_number();
        l_pred_act          table_number;
        l_comp_parent       table_number;
        l_inst_tab          table_number;
    
        l_seq NUMBER(24);
    
        l_aux_seq   table_number := table_number();
        l_aux_compo table_number := table_number();
        l_aux_inst  table_number := table_number();
    
        l_tab t_tbl_tmp := t_tbl_tmp(); -- t_rec_tmp
    
        FUNCTION get_sequence
        (
            i_institution IN NUMBER,
            i_old_seq     IN NUMBER
        ) RETURN NUMBER IS
            l_seq1 NUMBER(24);
        BEGIN
            SELECT t.new_seq
              INTO l_seq1
              FROM TABLE(l_tab) t
             WHERE t.old_seq = i_old_seq
               AND t.institution = i_institution;
            RETURN l_seq1;
        EXCEPTION
            WHEN no_data_found THEN
                SELECT seq_icnp_composition_hist.nextval
                  INTO l_seq1
                  FROM dual;
                l_tab.extend;
                l_tab(l_tab.count) := t_rec_tmp(i_institution, i_old_seq, l_seq1);
                RETURN l_seq1;
        END get_sequence;
    
    BEGIN
    
        EXECUTE IMMEDIATE 'drop INDEX ich_icn_fk_idx';
    
        l_inst := pk_list.tf_get_all_inst_group(i_inst, l_flg_rel);
    
        FOR x IN 1 .. l_inst.count
        LOOP
            --update inst 1
            IF x = l_inst.count
            THEN
            
                UPDATE icnp_composition ic
                   SET ic.id_institution = l_inst(x)
                 WHERE ic.id_institution IS NULL
                   AND ic.flg_available = pk_alert_constant.g_yes;
            
                UPDATE icnp_predefined_action ipa
                   SET ipa.id_institution = l_inst(x)
                 WHERE ipa.id_institution = pk_alert_constant.g_inst_all
                   AND ipa.flg_available = pk_alert_constant.g_yes;
            
                --update inst
                SELECT ic.id_composition BULK COLLECT
                  INTO l_composition
                  FROM icnp_composition ic
                 WHERE ic.id_institution = l_inst(x)
                   AND ic.flg_available = pk_alert_constant.g_yes; --available
            
                --check all composition
                FOR i IN 1 .. l_composition.count
                LOOP
                    l_table_old.extend;
                    l_table_old(l_table_old.last) := l_composition(i);
                    l_table_new.extend;
                    l_table_new(l_table_new.last) := l_composition(i);
                    l_table_inst.extend;
                    l_table_inst(l_table_inst.last) := l_inst(x);
                END LOOP;
            
                FOR l IN (SELECT *
                            FROM icnp_composition_hist ich
                           WHERE ich.flg_cancel = pk_alert_constant.g_no
                             AND ich.id_composition_hist NOT IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                                  t.new_seq
                                                                   FROM TABLE(l_tab) t))
                LOOP
                    l_aux_seq.extend;
                    l_aux_seq(l_aux_seq.last) := l.id_composition_hist;
                    l_aux_compo.extend;
                    l_aux_compo(l_aux_compo.last) := l.id_composition;
                    l_aux_inst.extend;
                    l_aux_inst(l_aux_inst.last) := l_inst(x);
                
                END LOOP;
            
            ELSE
                --insert new inst
                SELECT ic.id_composition BULK COLLECT
                  INTO l_composition
                  FROM icnp_composition ic
                 WHERE ic.id_institution IS NULL
                   AND ic.flg_available = pk_alert_constant.g_yes; --available
            
                --check all composition
                FOR i IN 1 .. l_composition.count
                LOOP
                    SELECT seq_icnp_composition.nextval
                      INTO l_new_comp
                      FROM dual;
                
                    INSERT INTO icnp_composition
                        (id_composition,
                         code_icnp_composition,
                         flg_type,
                         flg_nurse_tea,
                         flg_repeat,
                         flg_gender,
                         flg_available,
                         id_application_area,
                         id_doc_template,
                         adw_last_update,
                         id_institution,
                         id_software)
                        (SELECT l_new_comp,
                                'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION.' || l_new_comp,
                                ic.flg_type,
                                ic.flg_nurse_tea,
                                ic.flg_repeat,
                                ic.flg_gender,
                                ic.flg_available,
                                ic.id_application_area,
                                ic.id_doc_template,
                                ic.adw_last_update,
                                l_inst(x),
                                0
                           FROM icnp_composition ic
                          WHERE ic.id_composition = l_composition(i));
                
                    pk_translation.insert_into_translation(i_lang       => i_lang,
                                                           i_code_trans => 'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION.' ||
                                                                           l_new_comp,
                                                           i_desc_trans => pk_translation.get_translation(i_lang,
                                                                                                          'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION.' ||
                                                                                                          l_composition(i)));
                
                    l_table_old.extend;
                    l_table_old(l_table_old.last) := l_composition(i);
                    l_table_new.extend;
                    l_table_new(l_table_new.last) := l_new_comp;
                    l_table_inst.extend;
                    l_table_inst(l_table_inst.last) := l_inst(x);
                
                    INSERT INTO icnp_composition_term
                        (id_composition_term, id_term, id_composition, desc_term, rank, flg_main_focus, id_language)
                        (SELECT seq_icnp_composition_term.nextval,
                                id_term,
                                l_new_comp,
                                desc_term,
                                rank,
                                flg_main_focus,
                                id_language
                           FROM icnp_composition_term
                          WHERE id_composition = l_composition(i));
                
                    FOR q IN (SELECT *
                                FROM icnp_composition_hist ich
                               WHERE ich.flg_cancel = pk_alert_constant.g_no
                                 AND ich.id_composition = l_composition(i)
                                 AND ich.id_composition_hist NOT IN
                                     (SELECT /*+opt_estimate(table t rows=1)*/
                                       t.new_seq
                                        FROM TABLE(l_tab) t))
                    LOOP
                    
                        l_seq := get_sequence(l_inst(x), q.id_composition_hist);
                    
                        INSERT INTO icnp_composition_hist
                            (id_composition_hist, id_composition, flg_most_recent, dt_composition_hist, flg_cancel)
                        VALUES
                            (l_seq, q.id_composition, q.flg_most_recent, q.dt_composition_hist, q.flg_cancel);
                    
                        l_aux_seq.extend;
                        l_aux_seq(l_aux_seq.last) := l_seq;
                        l_aux_compo.extend;
                        l_aux_compo(l_aux_compo.last) := q.id_composition;
                        l_aux_inst.extend;
                        l_aux_inst(l_aux_inst.last) := l_inst(x);
                    
                    END LOOP;
                
                    SELECT ipa.id_predefined_action BULK COLLECT
                      INTO l_predefined_action
                      FROM icnp_predefined_action ipa
                     WHERE ipa.id_institution = pk_alert_constant.g_inst_all
                       AND ipa.flg_available = pk_alert_constant.g_yes
                       AND ipa.id_composition = l_composition(i);
                
                    --check predefined_actions
                    IF l_predefined_action.count > 0
                    THEN
                        FOR z IN 1 .. l_predefined_action.count
                        LOOP
                            SELECT seq_icnp_predefined_action.nextval
                              INTO l_new_pred_action
                              FROM dual;
                        
                            INSERT INTO icnp_predefined_action
                                (id_predefined_action,
                                 id_composition_parent,
                                 id_composition,
                                 id_institution,
                                 flg_available,
                                 id_software)
                                (SELECT l_new_pred_action,
                                        id_composition_parent,
                                        l_new_comp,
                                        l_inst(x),
                                        ipa.flg_available,
                                        0
                                   FROM icnp_predefined_action ipa
                                  WHERE ipa.id_predefined_action = l_predefined_action(z));
                        
                            INSERT INTO icnp_predefined_action_hist
                                (id_predefined_action_hist,
                                 id_predefined_action,
                                 flg_most_recent,
                                 dt_predefined_action_hist,
                                 id_professional,
                                 flg_cancel)
                                (SELECT seq_icnp_predef_action_hist.nextval,
                                        l_new_pred_action,
                                        flg_most_recent,
                                        dt_predefined_action_hist,
                                        id_professional,
                                        flg_cancel
                                   FROM icnp_predefined_action_hist
                                  WHERE id_predefined_action = l_predefined_action(z)
                                    AND flg_most_recent = pk_alert_constant.g_yes
                                    AND flg_cancel = pk_alert_constant.g_no);
                        
                        END LOOP;
                    END IF;
                END LOOP;
            END IF;
        END LOOP;
    
        SELECT ipa.id_predefined_action, ipa.id_composition_parent, ipa.id_institution BULK COLLECT
          INTO l_pred_act, l_comp_parent, l_inst_tab
          FROM icnp_predefined_action ipa
         WHERE ipa.id_institution <> l_inst(l_inst.count);
    
        FOR g IN 1 .. l_comp_parent.count
        LOOP
            FOR w IN 1 .. l_table_old.count
            LOOP
                IF l_comp_parent(g) = l_table_old(w)
                   AND l_inst_tab(g) = l_table_inst(w)
                THEN
                    UPDATE icnp_predefined_action
                       SET id_composition_parent = l_table_new(w)
                     WHERE id_predefined_action = l_pred_act(g);
                END IF;
            END LOOP;
        END LOOP;
    
        FOR r IN 1 .. l_table_old.count
        LOOP
            UPDATE icnp_predefined_action i
               SET i.id_composition = l_table_new(r)
             WHERE i.id_composition = l_table_old(r)
               AND i.id_institution = l_table_inst(r)
               AND i.flg_available = pk_alert_constant.g_yes;
        END LOOP;
    
        FOR t IN 1 .. l_aux_seq.count
        LOOP
            FOR r IN 1 .. l_table_old.count
            LOOP
                IF l_aux_compo(t) = l_table_old(r)
                   AND l_aux_inst(t) = l_table_inst(r)
                THEN
                    UPDATE icnp_composition_hist ich
                       SET ich.id_composition = l_table_new(r)
                     WHERE ich.id_composition_hist = l_aux_seq(t)
                       AND ich.id_composition = l_aux_compo(t);
                END IF;
            END LOOP;
        END LOOP;
    
        FOR e IN (SELECT icd.id_icnp_compo_dcs, icd.id_composition, icd.id_dep_clin_serv, d.id_institution
                    FROM icnp_compo_dcs icd
                    JOIN dep_clin_serv dcs
                      ON icd.id_dep_clin_serv = dcs.id_dep_clin_serv
                    JOIN department d
                      ON d.id_department = dcs.id_department
                   WHERE d.id_institution IN (SELECT /*+opt_estimate(table t rows=1)*/
                                               t.column_value
                                                FROM TABLE(l_inst) t))
        LOOP
            FOR w IN 1 .. l_table_old.count
            LOOP
                IF l_table_old(w) = e.id_composition
                   AND l_table_inst(w) = e.id_institution
                THEN
                    UPDATE icnp_compo_dcs
                       SET id_composition = l_table_new(w)
                     WHERE id_icnp_compo_dcs = e.id_icnp_compo_dcs;
                END IF;
            END LOOP;
        END LOOP;
    
        FOR t IN (SELECT itc.id_task, itc.id_task_type, itc.id_composition, itc.flg_available, itc.id_content
                    FROM icnp_task_composition itc)
        LOOP
            FOR u IN 1 .. l_table_old.count
            LOOP
                IF l_table_old(u) = t.id_composition
                   AND l_table_old(u) <> l_table_new(u)
                THEN
                    INSERT INTO icnp_task_composition
                        (id_task, id_task_type, id_composition, flg_available, id_content)
                    VALUES
                        (t.id_task, t.id_task_type, l_table_new(u), t.flg_available, t.id_content);
                END IF;
            END LOOP;
        END LOOP;
    
        FOR t IN (SELECT itcsi.id_task,
                         itcsi.id_task_type,
                         itcsi.id_composition,
                         itcsi.id_software,
                         itcsi.id_institution,
                         itcsi.flg_available
                    FROM icnp_task_comp_soft_inst itcsi)
        LOOP
            FOR u IN 1 .. l_table_old.count
            LOOP
                IF l_table_old(u) = t.id_composition
                   AND l_table_old(u) <> l_table_new(u)
                THEN
                    INSERT INTO icnp_task_comp_soft_inst
                        (id_task, id_task_type, id_composition, id_software, id_institution, flg_available)
                    VALUES
                        (t.id_task, t.id_task_type, l_table_new(u), t.id_software, t.id_institution, t.flg_available);
                END IF;
            END LOOP;
        END LOOP;
    
        FOR f IN (SELECT itcsi.id_task,
                         itcsi.id_task_type,
                         itcsi.id_composition,
                         itcsi.id_software,
                         itcsi.id_institution,
                         itcsi.flg_available
                    FROM icnp_task_comp_soft_inst itcsi)
        LOOP
            FOR p IN 1 .. l_table_new.count
            LOOP
                IF l_table_new(p) = f.id_composition
                THEN
                    UPDATE icnp_task_comp_soft_inst
                       SET id_institution = l_table_inst(p)
                     WHERE id_task = f.id_task
                       AND id_task_type = f.id_task_type
                       AND id_composition = f.id_composition
                       AND id_software = f.id_software
                       AND id_institution = f.id_institution;
                END IF;
            END LOOP;
        END LOOP;
    
        FORALL s IN 1 .. l_table_old.count
            INSERT INTO mig_cipe_aux
                (id_compo_old, id_compo_new, id_inst)
            VALUES
                (l_table_old(s), l_table_new(s), l_table_inst(s));
    
        EXECUTE IMMEDIATE 'CREATE UNIQUE INDEX ich_icn_fk_idx ON icnp_composition_hist(CASE WHEN(id_composition IS NOT NULL AND
                                                                           nvl(flg_most_recent, ''Y'') <> ''N'') THEN
                                                                      id_composition END,
                                                                      CASE WHEN(id_composition IS NOT NULL AND
                                                                           nvl(flg_most_recent, ''Y'') <> ''N'') THEN
                                                                      flg_most_recent END)';
    
        EXECUTE IMMEDIATE 'ALTER INDEX ich_icn_fk_idx rebuild tablespace table_m';
    
        EXECUTE IMMEDIATE 'analyze TABLE icnp_composition compute statistics FOR TABLE FOR ALL indexes FOR ALL indexed columns';
        EXECUTE IMMEDIATE 'analyze TABLE icnp_composition_hist compute statistics FOR TABLE FOR ALL indexes FOR ALL indexed columns';
        EXECUTE IMMEDIATE 'analyze TABLE icnp_composition_term compute statistics FOR TABLE FOR ALL indexes FOR ALL indexed columns';
        EXECUTE IMMEDIATE 'analyze TABLE icnp_predefined_action compute statistics FOR TABLE FOR ALL indexes FOR ALL indexed columns';
        EXECUTE IMMEDIATE 'analyze TABLE icnp_predefined_action_hist compute statistics FOR TABLE FOR ALL indexes FOR ALL indexed columns';
    
        --COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN FALSE;
    END mig_icnp_inst_group;

BEGIN
    -- Executes all the instructions needed to correctly initialize the package
    initialize();

END pk_icnp_util;
/
