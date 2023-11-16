/*-- Last Change Revision: $Rev: 2027657 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:55 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_scales_formulas IS

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    /********************************************************************************************
    *  Get the score (total or partial) as well as the class description.
    *
    * @param i_lang             Language identifier
    * @param i_prof             Professional
    * @param i_id_episode       Episode Id
    * @param i_doc_elements     Documentation element IDs of all template (total score) 
    *                           or the elements of a block (partial score)
    * @param i_flg_score_type   P -partial score; T-total score
    * @param o_score            score (total or partial)
    * @param o_descs            List with the descritives
    * @param o_error            Error
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           25-Mai-2011
    **********************************************************************************************/
    FUNCTION get_scale_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_scales      IN scales.id_scales%TYPE,
        i_score          IN NUMBER,
        i_scales_formula IN scales_formula.id_scales_formula%TYPE,
        o_desc_class     OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET class desc. i_id_episode: ' || i_id_episode || ' i_id_scales: ' || i_id_scales || ' i_score: ' ||
                   i_score;
        pk_alertlog.log_debug(g_error);
        SELECT decode(i_score,
                      NULL,
                      NULL,
                      pk_translation.get_translation(i_lang, s.code_scale_score) || ' - ' ||
                      pk_translation.get_translation(i_lang,
                                                     pk_inp_nurse.get_scales_class(i_lang,
                                                                                   i_prof,
                                                                                   i_score,
                                                                                   s.id_scales,
                                                                                   i_id_episode,
                                                                                   pk_alert_constant.g_scope_type_episode,
                                                                                   i_scales_formula))) desc_class
        
          INTO o_desc_class
          FROM scales s
         WHERE s.id_scales = i_id_scales;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_SCORE',
                                              o_error);
            RETURN FALSE;
    END get_scale_desc;

    -- Function and procedure implementations
    /********************************************************************************************
    *  Get the score value of the elements (of a scales group, a scale,  
    *  a group of elements regarding an id_documentation or a ist of doc_elements)
    *
    * @param i_lang             Language identifier
    * @param i_prof             Professional
    * @param i_id_episode       Episode Id
    * @param i_doc_elements     Documentation element IDs of all template (total score) 
    *                           or the elements of a block (partial score)
    * @param i_id_scales_group  Scales group id 
    * @param i_id_scales        Scales id
    * @param i_id_documentation Documentation id (groups of elements in a template)
    * @param o_score            score (total or partial)
    * @param o_descs            List with the descritives
    * @param o_error            Error
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           25-Mai-2011
    **********************************************************************************************/
    FUNCTION get_elements_score
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_doc_elements     IN table_number,
        i_id_scales_group  IN scales_group.id_scales_group%TYPE,
        i_id_scales        IN scales.id_scales%TYPE,
        i_id_documentation IN scales_group_rel.id_documentation%TYPE,
        i_id_doc_element   IN scales_formula.id_doc_element%TYPE
    ) RETURN t_tab_score_values IS
        l_element_values t_tab_score_values;
        l_error          t_error_out;
    BEGIN
        --GROUP scope
        IF (i_id_scales_group IS NOT NULL AND i_id_documentation IS NULL AND i_id_doc_element IS NULL)
        THEN
            g_error := 'GET score sum. i_id_scales_group: ' || i_id_scales_group;
            pk_alertlog.log_debug(g_error);
            SELECT t_rec_score_value(t.value, t.id_doc_element) BULK COLLECT
              INTO l_element_values
              FROM (SELECT DISTINCT sdv.value, sdv.id_doc_element
                      FROM scales_doc_value sdv
                      JOIN scales s
                        ON s.id_scales = sdv.id_scales
                      JOIN scales_group_rel sgr
                        ON sgr.id_scales = s.id_scales
                      JOIN (SELECT /*+opt_estimate(table,t,scale_rows=0.1)*/
                            column_value
                             FROM TABLE(i_doc_elements)) te
                        ON te.column_value = sdv.id_doc_element
                      JOIN doc_element de
                        ON de.id_doc_element = sdv.id_doc_element
                      JOIN documentation doc
                        ON doc.id_documentation = de.id_documentation
                     WHERE sgr.id_scales_group = i_id_scales_group
                       AND sdv.flg_available = pk_alert_constant.g_yes
                       AND sgr.flg_available = pk_alert_constant.g_yes
                       AND (doc.id_documentation = sgr.id_documentation OR
                           doc.id_documentation_parent = sgr.id_documentation)) t;
        
            --SCALES scope
        ELSIF (i_id_scales IS NOT NULL AND i_id_documentation IS NULL AND i_id_doc_element IS NULL)
        THEN
            g_error := 'GET score sum. i_id_scales_group: ' || i_id_scales_group;
            pk_alertlog.log_debug(g_error);
            SELECT t_rec_score_value(t.value, t.id_doc_element) BULK COLLECT
              INTO l_element_values
              FROM (SELECT DISTINCT sdv.value, sdv.id_doc_element
                      FROM scales_doc_value sdv
                      JOIN scales s
                        ON s.id_scales = sdv.id_scales
                      JOIN (SELECT /*+opt_estimate(table,t,scale_rows=0.1)*/
                            column_value
                             FROM TABLE(i_doc_elements)) te
                        ON te.column_value = sdv.id_doc_element
                     WHERE s.id_scales = i_id_scales
                       AND sdv.flg_available = pk_alert_constant.g_yes
                       AND s.flg_available = pk_alert_constant.g_yes) t;
            --DOCUMENTATION scope
        ELSIF (i_id_documentation IS NOT NULL)
        THEN
            g_error := 'GET score sum. i_id_documentation: ' || i_id_documentation;
            pk_alertlog.log_debug(g_error);
            SELECT t_rec_score_value(t.value, t.id_doc_element) BULK COLLECT
              INTO l_element_values
              FROM (SELECT DISTINCT sdv.value, sdv.id_doc_element
                      FROM doc_element de
                      JOIN documentation doc
                        ON doc.id_documentation = de.id_documentation
                      JOIN scales_doc_value sdv
                        ON sdv.id_doc_element = de.id_doc_element
                      JOIN scales s
                        ON s.id_scales = sdv.id_scales
                      JOIN (SELECT /*+opt_estimate(table,t,scale_rows=0.1)*/
                            column_value
                             FROM TABLE(i_doc_elements)) te
                        ON te.column_value = sdv.id_doc_element
                     WHERE (doc.id_documentation_parent = i_id_documentation OR
                           doc.id_documentation = i_id_documentation)
                       AND sdv.flg_available = pk_alert_constant.g_yes
                       AND s.flg_available = pk_alert_constant.g_yes) t;
        ELSE
            g_error := 'GET score cursor. i_id_episode: ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            SELECT t_rec_score_value(t.value, t.id_doc_element) BULK COLLECT
              INTO l_element_values
              FROM (SELECT DISTINCT sdv.value, sdv.id_doc_element
                      FROM scales_doc_value sdv
                     INNER JOIN scales s
                        ON s.id_scales = sdv.id_scales
                     INNER JOIN (SELECT /*+opt_estimate(table,t,scale_rows=0.1)*/
                                 column_value
                                  FROM TABLE(i_doc_elements) t) de
                        ON de.column_value = sdv.id_doc_element
                     WHERE sdv.flg_available = pk_alert_constant.g_yes
                       AND s.flg_available = pk_alert_constant.g_yes
                       AND (i_id_doc_element IS NULL OR sdv.id_doc_element = i_id_doc_element)) t;
        END IF;
    
        RETURN l_element_values;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ELEMENTS_SCORE',
                                              l_error);
            RETURN NULL;
    END get_elements_score;

    /********************************************************************************************
    *  Round a decimal number in order to it do not have more than 5 characters (including the dot)
    *
    * @param i_lang             Language identifier
    * @param i_prof             Professional
    * @param i_number           Input number    
    *
    * @return                  Formated number
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           25-Mai-2011
    **********************************************************************************************/
    FUNCTION round_number
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_number IN NUMBER
    ) RETURN VARCHAR2 IS
        l_score      NUMBER;
        l_number_str VARCHAR2(50 CHAR);
        l_error      t_error_out;
    BEGIN
    
        -- if the number is decimal round it in order to do not have more than 5 digits (including the dot)
        IF NOT regexp_like(i_number, '^[0-9]+$')
        THEN
            IF (i_number < 10)
            THEN
                l_score := round(i_number, 3);
            ELSIF (i_number > 10 AND i_number < 100)
            THEN
                -- it can only have 2 decimal digits
                l_score := round(i_number, 2);
            ELSIF (i_number > 100 AND i_number < 1000)
            THEN
                -- it can only have 1 decimal digits
                l_score := round(i_number, 1);
            ELSIF (i_number > 1000)
            THEN
                l_score := round(i_number, 0);
            END IF;
        
            IF (i_number < 1 AND i_number > 0)
            THEN
                l_number_str := '˜0';
            ELSE
                l_number_str := NULL;
            END IF;
        ELSE
            l_score := i_number;
        END IF;
    
        l_number_str := l_number_str || to_char(l_score);
    
        RETURN l_number_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'ROUND_NUMBER',
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END round_number;

    /********************************************************************************************
    *  Get the default formula to be used when no formula is configured
    *
    * @param i_lang             Language identifier
    * @param i_prof             Professional
    * @param i_id_scales_group  Scales group id 
    * @param i_id_scales        Scales id
    * @param i_id_documentation Documentation id (groups of elements in a template)
    * @param i_doc_element      Documentation element ID
    *
    * @return                          formulas info
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           06-Jul-2011
    **********************************************************************************************/
    FUNCTION get_default_formula
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_scales_group  IN scales_group.id_scales_group%TYPE,
        i_id_scales        IN scales.id_scales%TYPE,
        i_id_documentation IN scales_group_rel.id_documentation%TYPE,
        i_id_doc_element   IN doc_element.id_doc_element%TYPE
    ) RETURN t_tab_score_formulas IS
        l_formulas t_tab_score_formulas := t_tab_score_formulas();
        l_error    t_error_out;
    BEGIN
        g_error := 'DEFAULT FORMULA';
        pk_alertlog.log_debug(g_error);
    
        l_formulas := t_tab_score_formulas();
        l_formulas.extend();
        l_formulas(1) := t_rec_score_formula(NULL,
                                             pk_scales_constant.g_formula_sum,
                                             NULL,
                                             NULL,
                                             i_id_scales,
                                             i_id_scales_group,
                                             i_id_documentation,
                                             i_id_doc_element,
                                             CASE
                                                 WHEN i_id_documentation IS NULL
                                                      AND i_id_scales_group IS NULL THEN
                                                  pk_scales_constant.g_formula_type_tm
                                                 ELSE
                                                  pk_scales_constant.g_formula_type_pm
                                             END,
                                             NULL,
                                             NULL,
                                             NULL,
                                             pk_alert_constant.g_yes,
                                             pk_alert_constant.g_no);
    
        RETURN l_formulas;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DEFAULT_FORMULA',
                                              l_error);
            RETURN NULL;
    END get_default_formula;

    /********************************************************************************************
    *  Get the alias in the formulas
    *
    * @param i_lang             Language identifier
    * @param i_prof             Professional
    * @param i_formulas         Formulas list 
    * @param io_final_alias     Alias list   
    * @param o_error            Error 
    *
    * @return                          success/error
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.2
    * @since                           19-Jul-2011
    **********************************************************************************************/
    FUNCTION get_alias
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_formulas     IN table_varchar,
        io_final_alias IN OUT table_varchar,
        o_alias        OUT table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET ALIAS USED IN THE FORMULAS';
        pk_alertlog.log_debug(g_error);
        o_alias := pk_string_utils.get_str_between_chars(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_strs      => i_formulas,
                                                         i_start_chr => pk_scales_constant.g_formula_alias_start,
                                                         i_end_chr   => pk_scales_constant.g_formula_alias_end);
        IF (o_alias IS NOT NULL)
        THEN
            g_error := 'CALL pk_inp_nurse.append_tables.';
            IF NOT pk_utils.append_tables(i_lang            => i_lang,
                                          i_prof            => i_prof,
                                          i_table_to_append => o_alias,
                                          i_flg_replace     => pk_alert_constant.g_no,
                                          i_replacement     => NULL,
                                          io_total_table    => io_final_alias,
                                          o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ALIAS',
                                              o_error);
            RETURN FALSE;
        
    END get_alias;

    /********************************************************************************************
    *  Get the score_calculation_formulas (of a scales group, a scale,  
    *  a group of elements regarding an id_documentation or a ist of doc_elements)
    *
    * @param i_lang             Language identifier
    * @param i_prof             Professional
    * @param i_id_scales_group  Scales group id 
    * @param i_id_scales        Scales id
    * @param i_id_documentation Documentation id (groups of elements in a template)
    * @param i_doc_element      Documentation element ID
    *
    * @return                          formulas info
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           29-Jun-2011
    **********************************************************************************************/
    FUNCTION get_formulas
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_scales_group  IN scales_group.id_scales_group%TYPE,
        i_id_scales        IN scales.id_scales%TYPE,
        i_id_documentation IN scales_group_rel.id_documentation%TYPE,
        i_id_doc_element   IN doc_element.id_doc_element%TYPE
    ) RETURN t_tab_score_formulas IS
        l_formulas     t_tab_score_formulas := t_tab_score_formulas();
        final_formulas t_tab_score_formulas := t_tab_score_formulas();
        l_forms        table_varchar;
        l_alias        table_varchar;
        l_error        t_error_out;
        j              PLS_INTEGER := 0;
        l_total_alias  table_varchar := table_varchar();
    BEGIN
        g_error := 'GET formulas. i_id_scales_group: ' || i_id_scales_group || ' i_id_scales: ' || i_id_scales ||
                   ' i_id_documentation: ' || i_id_documentation || ' i_id_doc_element: ' || i_id_doc_element;
        pk_alertlog.log_debug(g_error);
    
        SELECT t_rec_score_formula(tsf.id_scales_formula,
                                   tsf.formula,
                                   tsf.formula_alias,
                                   NULL,
                                   tsf.id_scales,
                                   tsf.id_scales_group,
                                   tsf.id_documentation,
                                   tsf.id_doc_element,
                                   tsf.flg_formula_type,
                                   pk_translation.get_translation(i_lang, tsf.code_scales_formula),
                                   tsf.rank,
                                   NULL,
                                   tsf.flg_visible,
                                   tsf.flg_summary),
               tsf.formula BULK COLLECT
          INTO l_formulas, l_forms
          FROM (SELECT sf.id_scales_formula,
                        sf.formula,
                        sf.formula_alias,
                        sf.id_scales,
                        sf.id_scales_group,
                        sf.id_documentation,
                        sf.id_doc_element,
                        sf.flg_formula_type,
                        sf.code_scales_formula,
                        sf.rank,
                        sf.flg_visible,
                        sf.flg_summary
                   FROM scales_formula sf
                  WHERE -- scales_group scope
                  ((i_id_scales_group IS NOT NULL AND i_id_scales IS NOT NULL AND i_id_documentation IS NULL AND
                  sf.id_scales_group = i_id_scales_group AND sf.id_scales = i_id_scales AND sf.id_documentation IS NULL))
               AND sf.flg_available = pk_alert_constant.get_yes
                 UNION ALL
                 SELECT sf.id_scales_formula,
                        sf.formula,
                        sf.formula_alias,
                        sf.id_scales,
                        sf.id_scales_group,
                        sf.id_documentation,
                        sf.id_doc_element,
                        sf.flg_formula_type,
                        sf.code_scales_formula,
                        sf.rank,
                        sf.flg_visible,
                        sf.flg_summary
                   FROM scales_formula sf
                  WHERE -- scales scope
                  (i_id_scales IS NOT NULL AND i_id_scales_group IS NULL AND i_id_documentation IS NULL AND
                  sf.id_scales = i_id_scales AND sf.id_scales_group IS NULL AND sf.id_documentation IS NULL AND
                  sf.id_doc_element IS NULL)
               AND sf.flg_available = pk_alert_constant.get_yes
                 UNION ALL
                 SELECT sf.id_scales_formula,
                        sf.formula,
                        sf.formula_alias,
                        sf.id_scales,
                        sf.id_scales_group,
                        sf.id_documentation,
                        sf.id_doc_element,
                        sf.flg_formula_type,
                        sf.code_scales_formula,
                        sf.rank,
                        sf.flg_visible,
                        sf.flg_summary
                   FROM scales_formula sf
                  WHERE -- documentation scope
                  (i_id_documentation IS NOT NULL AND sf.id_documentation = i_id_documentation)
               AND sf.flg_available = pk_alert_constant.get_yes) tsf;
    
        g_error := 'CALL get_alias';
        pk_alertlog.log_debug(g_error);
        IF NOT get_alias(i_lang         => i_lang,
                         i_prof         => i_prof,
                         i_formulas     => l_forms,
                         io_final_alias => l_total_alias,
                         o_alias        => l_alias,
                         o_error        => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        WHILE (l_alias IS NOT NULL AND l_alias.exists(1) AND l_alias(1) IS NOT NULL AND j < 100)
        LOOP
            --get all the alias of all the formulas used in the current formula
            g_error := 'GET formulas from alias';
            pk_alertlog.log_debug(g_error);
            SELECT sf.formula BULK COLLECT
              INTO l_forms
              FROM scales_formula sf
             WHERE sf.id_scales = i_id_scales
               AND sf.formula_alias IN (SELECT /*+opt_estimate (table t rows=1)*/
                                         column_value
                                          FROM TABLE(l_alias) t)
               AND sf.flg_available = pk_alert_constant.g_yes;
        
            g_error := 'CALL get_alias';
            pk_alertlog.log_debug(g_error);
            IF NOT get_alias(i_lang         => i_lang,
                             i_prof         => i_prof,
                             i_formulas     => l_forms,
                             io_final_alias => l_total_alias,
                             o_alias        => l_alias,
                             o_error        => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
            j := j + 1;
        
        END LOOP;
    
        g_error := 'GET ALL FORMULAS';
        pk_alertlog.log_debug(g_error);
        SELECT t_rec_score_formula(t.id_scales_formula,
                                   t.formula,
                                   t.formula_alias,
                                   NULL,
                                   t.id_scales,
                                   t.id_scales_group,
                                   t.id_documentation,
                                   t.id_doc_element,
                                   t.flg_formula_type,
                                   t.description,
                                   t.rank,
                                   NULL,
                                   t.flg_visible,
                                   t.flg_summary) BULK COLLECT
          INTO final_formulas
          FROM (SELECT s.id_scales_formula,
                       s.formula,
                       s.formula_alias,
                       s.id_scales,
                       s.id_scales_group,
                       s.id_documentation,
                       s.id_doc_element,
                       s.flg_formula_type,
                       s.description,
                       s.rank,
                       s.flg_visible,
                       s.flg_summary,
                       row_number() over(PARTITION BY s.id_scales_formula ORDER BY s.rank) rn
                  FROM (SELECT sf.id_scales_formula,
                               sf.formula,
                               sf.formula_alias,
                               sf.id_scales,
                               sf.id_scales_group,
                               sf.id_documentation,
                               sf.id_doc_element,
                               sf.flg_formula_type,
                               pk_translation.get_translation(i_lang, sf.code_scales_formula) description,
                               sf.rank,
                               sf.flg_visible,
                               sf.flg_summary
                          FROM scales_formula sf
                         WHERE sf.id_scales = i_id_scales
                           AND sf.formula_alias IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                     column_value
                                                      FROM TABLE(l_total_alias) t)
                           AND sf.flg_available = pk_alert_constant.g_yes
                        UNION ALL
                        SELECT l.id_scales_formula,
                               l.formula,
                               l.formula_alias,
                               l.id_scales,
                               l.id_scales_group,
                               l.id_documentation,
                               l.id_doc_element,
                               l.flg_formula_type,
                               l.description,
                               l.rank,
                               l.flg_visible,
                               l.flg_summary
                          FROM TABLE(l_formulas) l) s) t
         WHERE t.rn = 1
         ORDER BY t.rank;
    
        /*IF (NOT final_formulas.exists(1))
        THEN
            g_error := 'CALL get_default_formula';
            pk_alertlog.log_debug(g_error);
            final_formulas := get_default_formula(i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_id_scales_group  => i_id_scales_group,
                                                  i_id_scales        => i_id_scales,
                                                  i_id_documentation => i_id_documentation,
                                                  i_id_doc_element   => i_id_doc_element);
        END IF;*/
    
        RETURN final_formulas;
    
    EXCEPTION
        WHEN no_data_found THEN
            --when there is no configured formula consider the default formula: SUM
            /*l_formulas := get_default_formula(i_lang             => i_lang,
            i_prof             => i_prof,
            i_id_scales_group  => i_id_scales_group,
            i_id_scales        => i_id_scales,
            i_id_documentation => i_id_documentation,
            i_id_doc_element   => i_id_doc_element);*/
            RETURN l_formulas;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_FORMULAS',
                                              l_error);
            RETURN NULL;
    END get_formulas;

    /********************************************************************************************
    *  Get the score (total or partial) as well as the class description.
    *
    * @param i_lang             Language identifier
    * @param i_prof             Professional
    * @param i_score_values     Structure with the score associated to the elements that should 
    *                           be considered to the score calculation
    * @param i_operation        Arithmetic operation that should be used between all the scores of 
    *                           the diferent elements
    * @param o_formula_to_calc  Final formula to calculate the score: 
    *                           replace the score values in the inicial formula
    * @param o_error            Error
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           29-Jun-2011
    **********************************************************************************************/
    FUNCTION get_arithmetic_calc_formula
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_score_values    IN t_tab_score_values,
        i_operation       IN VARCHAR2,
        o_formula_to_calc OUT CLOB,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_score_values table_varchar;
    BEGIN
        g_error := 'GET scores numbers in char';
        pk_alertlog.log_debug(g_error);
        SELECT REPLACE(to_char(ts.value /*, '999.999'*/), ',', '.') BULK COLLECT
          INTO l_score_values
          FROM (SELECT /*+opt_estimate (table t rows=1)*/
                 t.value
                  FROM TABLE(i_score_values) t) ts;
    
        g_error := 'CALL pk_utils.concat_table';
        pk_alertlog.log_debug(g_error);
        o_formula_to_calc := pk_utils.concat_table(i_tab => l_score_values, i_delim => i_operation);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ARITHMETIC_CALC_FORMULA',
                                              o_error);
            RETURN FALSE;
    END get_arithmetic_calc_formula;

    /********************************************************************************************
    *  Get the score (total or partial) as well as the class description.
    *
    * @param i_lang             Language identifier
    * @param i_prof             Professional
    * @param i_score_values     Structure with the score associated to the elements that should 
    *                           be considered to the score calculation
    * @param i_operation        Arithmetic operation that should be used between all the scores of 
    *                           the diferent elements
    * @param o_formula_to_calc  Final formula to calculate the score: 
    *                           replace the score values in the inicial formula
    * @param o_error            Error
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           29-Jun-2011
    **********************************************************************************************/
    FUNCTION get_score_sum
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_score_values    IN t_tab_score_values,
        o_formula_to_calc OUT CLOB,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL get_arithmetic_calc_formula';
        pk_alertlog.log_debug(g_error);
        IF NOT get_arithmetic_calc_formula(i_lang            => i_lang,
                                           i_prof            => i_prof,
                                           i_score_values    => i_score_values,
                                           i_operation       => pk_scales_constant.g_operator_plus,
                                           o_formula_to_calc => o_formula_to_calc,
                                           o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ARITHMETIC_CALC_FORMULA',
                                              o_error);
            RETURN FALSE;
    END get_score_sum;

    /********************************************************************************************
    *  Executes the calcution of the formula, and returns the score value.
    *
    * @param i_lang             Language identifier
    * @param i_prof             Professional
    * @param i_scales_formula   Formula with all replaced values. Ready to be done the mathematics calculation    
    * @param o_error            score value
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           29-Jun-2011
    **********************************************************************************************/
    FUNCTION get_exec_formula
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_scales_formula IN scales_formula.formula%TYPE
    ) RETURN NUMBER IS
        l_score_calc_form CLOB;
        l_error           t_error_out;
        l_score           NUMBER(24, 15);
    BEGIN
        IF (i_scales_formula IS NOT NULL)
        THEN
            l_score_calc_form := 'select ' || i_scales_formula || ' from dual';
            EXECUTE IMMEDIATE l_score_calc_form
                INTO l_score;
        END IF;
    
        RETURN l_score;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_EXEC_FORMULA',
                                              l_error);
            RETURN NULL;
    END get_exec_formula;

    /********************************************************************************************
    *  Get the final formula to be used on score calculation. 
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_formula                  Configured formula
    * @param i_scores                   Element scores info
    * @param i_nr_answered_questions    Nr of answered questions in the template    
    * @param o_final_formula            Final formula
    * @param o_error                    Error
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           25-Mai-2011
    **********************************************************************************************/
    FUNCTION get_final_formula
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_doc_elements          IN table_number,
        i_formula               IN scales_formula.formula%TYPE,
        i_scores                IN t_tab_score_values,
        i_nr_answered_questions IN PLS_INTEGER,
        o_final_formula         OUT CLOB,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_formula_to_calc   CLOB;
        l_nr_answered_quest PLS_INTEGER;
        l_max_score         scales_doc_value.value%TYPE;
    BEGIN
        o_final_formula := i_formula;
    
        IF (i_scores IS NULL OR NOT i_scores.exists(1))
        THEN
            o_final_formula := NULL;
        ELSE
        
            IF (i_formula LIKE
               pk_scales_constant.g_percentage || pk_scales_constant.g_formula_sum || pk_scales_constant.g_percentage)
            THEN
                g_error := 'CALL get_score_sum.';
                pk_alertlog.log_debug(g_error);
                IF NOT get_score_sum(i_lang            => i_lang,
                                     i_prof            => i_prof,
                                     i_score_values    => i_scores,
                                     o_formula_to_calc => l_formula_to_calc,
                                     o_error           => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                IF (l_formula_to_calc IS NOT NULL)
                THEN
                    g_error := 'REPLACE SUM CODE IN FORMULA.';
                    pk_alertlog.log_debug(g_error);
                    o_final_formula := REPLACE(i_formula,
                                               pk_scales_constant.g_formula_sum,
                                               pk_scales_constant.g_open_parenthesis || l_formula_to_calc ||
                                               pk_scales_constant.g_close_parenthesis);
                END IF;
            END IF;
        
            IF (i_formula LIKE
               pk_scales_constant.g_percentage || pk_scales_constant.g_formula_mult || pk_scales_constant.g_percentage)
            THEN
                g_error := 'CALL get_arithmetic_calc_formula mult';
                pk_alertlog.log_debug(g_error);
                IF NOT get_arithmetic_calc_formula(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_score_values    => i_scores,
                                                   i_operation       => pk_scales_constant.g_operator_mult,
                                                   o_formula_to_calc => l_formula_to_calc,
                                                   o_error           => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                IF (l_formula_to_calc IS NOT NULL)
                THEN
                    g_error := 'REPLACE mult CODE IN FORMULA.';
                    pk_alertlog.log_debug(g_error);
                    o_final_formula := REPLACE(i_formula,
                                               pk_scales_constant.g_formula_mult,
                                               pk_scales_constant.g_open_parenthesis || l_formula_to_calc ||
                                               pk_scales_constant.g_close_parenthesis);
                END IF;
            END IF;
        
            IF (i_formula LIKE pk_scales_constant.g_percentage || pk_scales_constant.g_formula_nr_answers ||
               pk_scales_constant.g_percentage)
            THEN
                g_error := 'REPLACE nr_answers CODE IN FORMULA.';
                pk_alertlog.log_debug(g_error);
                o_final_formula := REPLACE(o_final_formula,
                                           pk_scales_constant.g_formula_nr_answers,
                                           to_char(i_scores.count));
            END IF;
        
            IF (i_formula LIKE pk_scales_constant.g_percentage || pk_scales_constant.g_formula_nr_answ_questions ||
               pk_scales_constant.g_percentage)
            THEN
                IF (i_nr_answered_questions IS NULL)
                THEN
                    g_error := 'CALL get_nr_answered_questions';
                    pk_alertlog.log_debug(g_error);
                    IF NOT get_nr_answered_questions(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_scores       => i_scores,
                                                     o_nr_questions => l_nr_answered_quest,
                                                     o_error        => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                ELSE
                    l_nr_answered_quest := i_nr_answered_questions;
                END IF;
            
                g_error := 'REPLACE nr_answ_questions CODE IN FORMULA.';
                pk_alertlog.log_debug(g_error);
                o_final_formula := REPLACE(o_final_formula,
                                           pk_scales_constant.g_formula_nr_answ_questions,
                                           to_char(l_nr_answered_quest));
            END IF;
        
            IF (i_formula LIKE
               pk_scales_constant.g_percentage || pk_scales_constant.g_formula_max || pk_scales_constant.g_percentage)
            THEN
                g_error := 'CALL get_max_score';
                pk_alertlog.log_debug(g_error);
                IF NOT get_max_score(i_lang      => i_lang,
                                     i_prof      => i_prof,
                                     i_scores    => i_scores,
                                     o_max_score => l_max_score,
                                     o_error     => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                g_error := 'REPLACE max CODE IN FORMULA.';
                pk_alertlog.log_debug(g_error);
                o_final_formula := REPLACE(o_final_formula, pk_scales_constant.g_formula_max, to_char(l_max_score));
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_FINAL_FORMULA',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_final_formula;

    /********************************************************************************************
    *  Get the elements to be used in the final formula and construct the final formula 
    *  for score calculation based on the elements. 
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_doc_elements             Doc elements list selected by the user
    * @param i_id_scales_group          Scales group id
    * @param i_id_scales                Scales id
    * @param i_id_documentation         Documentation id
    * @param i_id_doc_element           Doc element id
    * @param i_formula                  Calculation formula
    * @param i_nr_answered_questions    Nr of answered questions in the template    
    * @param o_final_formula            Final formula
    * @param o_error                    Error
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           25-Mai-2011
    **********************************************************************************************/
    FUNCTION get_elements_and_formula
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_doc_elements          IN table_number,
        i_id_scales_group       IN scales_group.id_scales_group%TYPE,
        i_id_scales             IN scales.id_scales%TYPE,
        i_id_documentation      IN scales_formula.id_documentation%TYPE,
        i_id_doc_element        IN scales_formula.id_doc_element%TYPE,
        i_formula               IN scales_formula.formula%TYPE,
        i_nr_answered_questions IN PLS_INTEGER,
        o_final_formula         OUT CLOB,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_scores t_tab_score_values := t_tab_score_values();
    BEGIN
        o_final_formula := i_formula;
    
        g_error := 'CALL get_elements_score. i_id_scales_group: ' || i_id_scales_group || ' i_id_scales: ' ||
                   i_id_scales || ' i_id_documentation: ' || i_id_documentation;
        pk_alertlog.log_debug(g_error);
        l_scores := get_elements_score(i_lang             => i_lang,
                                       i_prof             => i_prof,
                                       i_id_episode       => i_id_episode,
                                       i_doc_elements     => i_doc_elements,
                                       i_id_scales_group  => i_id_scales_group,
                                       i_id_scales        => i_id_scales,
                                       i_id_documentation => i_id_documentation,
                                       i_id_doc_element   => i_id_doc_element);
    
        g_error := 'CALL get_final_formula.';
        pk_alertlog.log_debug(g_error);
        IF NOT get_final_formula(i_lang                  => i_lang,
                                 i_prof                  => i_prof,
                                 i_doc_elements          => i_doc_elements,
                                 i_formula               => i_formula,
                                 i_scores                => l_scores,
                                 i_nr_answered_questions => i_nr_answered_questions,
                                 o_final_formula         => o_final_formula,
                                 o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ELEMENTS_AND_FORMULA',
                                              o_error);
            RETURN FALSE;
    END get_elements_and_formula;

    /********************************************************************************************
    *  Get the complementary formulas and descriptions.
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_formulas                 Formulas info    
    * @param o_descs                    Scales complementary formulas scores results.
    * @param o_id_scales_formulas       Formulas Id list
    * @param o_values                   Score values
    * @param o_rankq                    Formula Rank
    * @param o_error                    Error
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           07-Jul-2011
    **********************************************************************************************/
    FUNCTION get_compl_descriptions
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_formulas           IN t_tab_score_formulas,
        o_descs              OUT table_varchar,
        o_id_scales_formulas OUT table_number,
        o_values             OUT table_varchar,
        o_rank               OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALCULATE THE COMPLEMENTARY SCORES.';
        pk_alertlog.log_debug(g_error);
        SELECT REPLACE(tff.description, pk_scales_constant.g_replace_1, score_value),
               tff.id_scales_formula,
               tff.rank,
               tff.score_value BULK COLLECT
          INTO o_descs, o_id_scales_formulas, o_values, o_rank
          FROM (SELECT tf.description,
                       tf.id_scales_formula,
                       tf.rank,
                       round_number(i_lang, i_prof, get_exec_formula(i_lang, i_prof, tf.formula_to_calc)) score_value
                  FROM TABLE(i_formulas) tf
                 WHERE tf.flg_formula_type = pk_scales_constant.g_formula_type_c) tff;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_COMPL_DESCRIPTIONS',
                                              o_error);
            RETURN FALSE;
    END get_compl_descriptions;

    /********************************************************************************************
    *  Get the class description(s) and/or the complementary formulas descriptions.
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_id_episode               Episode Id    
    * @param i_id_scales                Scales Id 
    * @param i_score_values             Calculated score info
    * @param i_formulas                 Formulas to calculate the score values of the complementary formulas
    * @param o_descs                    Scales decritions and complementary formulas results.
    * @param o_error                    Error
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           25-Mai-2011
    **********************************************************************************************/
    FUNCTION get_class_compl_descriptions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_scales  IN scales.id_scales%TYPE,
        i_formulas   IN t_tab_score_formulas,
        o_descs      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_desc_class         pk_translation.t_desc_translation;
        l_descs_class        table_varchar;
        l_comp_scores        table_varchar;
        l_id_scales_formulas table_number;
        l_values             table_varchar;
        l_rank               table_number;
    BEGIN
        l_descs_class := table_varchar();
    
        FOR rec IN (SELECT t.id_scales_formula, t.score_value
                      FROM TABLE(i_formulas) t
                     WHERE t.flg_formula_type IN
                           (pk_scales_constant.g_formula_type_tm, pk_scales_constant.g_formula_type_pm))
        LOOP
            g_error := 'CALL pk_inp_nurse.get_scales_class. i_id_episode: ' || i_id_episode || ' i_id_scales: ' ||
                       i_id_scales || ' i_score: ' || rec.score_value;
            pk_alertlog.log_debug(g_error);
            l_desc_class := pk_translation.get_translation(i_lang,
                                                           pk_inp_nurse.get_scales_class(i_lang              => i_lang,
                                                                                         i_prof              => i_prof,
                                                                                         i_value             => rec.score_value,
                                                                                         i_scales            => i_id_scales,
                                                                                         i_scope             => i_id_episode,
                                                                                         i_scope_type        => pk_alert_constant.g_scope_type_episode,
                                                                                         i_id_scales_formula => rec.id_scales_formula));
        
            IF (l_desc_class IS NOT NULL)
            THEN
                l_descs_class.extend;
                l_descs_class(l_descs_class.last) := l_desc_class;
            END IF;
        END LOOP;
    
        g_error := 'CALL get_compl_descriptions.';
        pk_alertlog.log_debug(g_error);
        IF NOT get_compl_descriptions(i_lang               => i_lang,
                                      i_prof               => i_prof,
                                      i_formulas           => i_formulas,
                                      o_descs              => l_comp_scores,
                                      o_id_scales_formulas => l_id_scales_formulas,
                                      o_values             => l_values,
                                      o_rank               => l_rank,
                                      o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF (l_comp_scores IS NOT NULL OR l_comp_scores.exists(1))
        THEN
            OPEN o_descs FOR
                SELECT *
                  FROM (SELECT tdesc.description, tform.id_scales_formula, tval.score_value
                          FROM ((SELECT column_value description, rownum rndesc
                                   FROM TABLE(l_comp_scores)) tdesc JOIN
                                (SELECT column_value id_scales_formula, rownum rnform
                                   FROM TABLE(l_id_scales_formulas)) tform ON tform.rnform = tdesc.rndesc JOIN
                                (SELECT column_value score_value, rownum rnval
                                   FROM TABLE(l_values)) tval ON tval.rnval = tform.rnform JOIN
                                (SELECT column_value rank, rownum rnr
                                   FROM TABLE(l_rank)) tval ON tval.rnr = tval.rnval)
                        UNION ALL
                        SELECT column_value description, NULL id_scales_formula, NULL score_value
                          FROM TABLE(l_descs_class));
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_descs);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_descs);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ELEMENTS_SCORE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_class_compl_descriptions;

    /********************************************************************************************
    *  Get the score (total or partial)
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_id_episode               Episode Id
    * @param i_id_scales_group          Scales group Id
    * @param i_id_scales                Scales Id 
    * @param i_id_documentation         Documentation parent Id
    * @param i_doc_elements             Doc elements Ids        
    * @param i_nr_answered_questions    Nr of ansered questions or filled elements
    * @param o_error                    Error
    *
    * @return                          Scores
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           25-Mai-2011
    **********************************************************************************************/
    FUNCTION get_calculated_scores
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_scales_group       IN scales_group.id_scales_group%TYPE,
        i_id_scales             IN scales.id_scales%TYPE,
        i_id_documentation      IN documentation.id_documentation%TYPE,
        i_doc_elements          IN table_number,
        i_nr_answered_questions IN PLS_INTEGER
    ) RETURN t_tab_score_formulas IS
        l_formulas          t_tab_score_formulas := t_tab_score_formulas();
        l_total_msg         sys_message.code_message%TYPE;
        l_first_level       PLS_INTEGER := 0;
        l_nr_answered_quest PLS_INTEGER;
        l_error             t_error_out;
    BEGIN
        g_error := 'GET score cursor. i_id_episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
    
        --get the formulas which result should be returned
        g_error := 'CALL get_formulas. i_id_scales_group: ' || i_id_scales_group || ' i_id_scales: ' || i_id_scales ||
                   ' i_id_documentation: ' || i_id_documentation;
        pk_alertlog.log_debug(g_error);
        l_formulas := get_formulas(i_lang             => i_lang,
                                   i_prof             => i_prof,
                                   i_id_scales_group  => i_id_scales_group,
                                   i_id_scales        => i_id_scales,
                                   i_id_documentation => i_id_documentation,
                                   i_id_doc_element   => NULL);
    
        FOR i IN 1 .. l_formulas.count
        LOOP
            -- for a given formula associated to a group, documentation or scale
            -- we need to calculate first all the children: The formulas list cames ordered and begins with the childrens                                  
            g_error := 'CALL get_elements_and_formula. i_id_scales_group: ' || l_formulas(i).id_scales_group ||
                       ' i_id_scales: ' || l_formulas(i).id_scales || ' i_id_documentation: ' || l_formulas(i)
                      .id_documentation || ' i_id_doc_element: ' || l_formulas(i).id_doc_element;
            pk_alertlog.log_debug(g_error);
            IF NOT get_elements_and_formula(i_lang                  => i_lang,
                                            i_prof                  => i_prof,
                                            i_id_episode            => i_id_episode,
                                            i_doc_elements          => i_doc_elements,
                                            i_id_scales_group       => l_formulas(i).id_scales_group,
                                            i_id_scales             => l_formulas(i).id_scales,
                                            i_id_documentation      => l_formulas(i).id_documentation,
                                            i_id_doc_element        => l_formulas(i).id_doc_element,
                                            i_formula               => l_formulas(i).formula,
                                            i_nr_answered_questions => l_nr_answered_quest,
                                            o_final_formula         => l_formulas(i).formula_to_calc,
                                            o_error                 => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
            IF (l_formulas(i).rank <> l_first_level AND i <> 1)
            THEN
                --get the previous values and replace them in the actual formula
                g_error := 'REPLACE the previous calculated formulas';
                pk_alertlog.log_debug(g_error);
                FOR rec IN (SELECT tf.formula_to_calc, tf.formula_alias
                              FROM TABLE(l_formulas) tf
                             WHERE tf.rank < l_formulas(i).rank)
                LOOP
                    l_formulas(i).formula_to_calc := REPLACE(l_formulas(i).formula_to_calc,
                                                             pk_scales_constant.g_formula_alias_start ||
                                                             rec.formula_alias || pk_scales_constant.g_formula_alias_end,
                                                             rec.formula_to_calc);
                END LOOP;
            
            ELSIF (i = 1)
            THEN
                l_first_level := l_formulas(i).rank;
            END IF;
        END LOOP;
    
        g_error := 'CALL pk_message.get_message.';
        pk_alertlog.log_debug(g_error);
        l_total_msg := pk_message.get_message(i_lang => i_lang, i_code_mess => pk_scales_constant.g_total_msg);
    
        g_error := 'CALCULATE THE MAIN SCORES.';
        pk_alertlog.log_debug(g_error);
        --execute the formulas in order to obtain the values
        FOR i IN 1 .. l_formulas.count
        LOOP
            l_formulas(i).description := CASE
                                             WHEN l_formulas(i).description IS NULL THEN
                                              l_total_msg
                                             ELSE
                                              l_formulas(i).description
                                         END;
            l_formulas(i).score_value := get_exec_formula(i_lang, i_prof, l_formulas(i).formula_to_calc);
        END LOOP;
    
        RETURN l_formulas;
    
    EXCEPTION
        WHEN g_exception THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_CALCULATED_SCORES',
                                              l_error);
            RETURN NULL;
    END get_calculated_scores;

    /********************************************************************************************
    *  Get the score (total or partial) considering the id_epis_documentation.
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_id_episode               Episode Id
    * @param i_id_scales_group          Scales group Id
    * @param i_id_scales                Scales Id 
    * @param i_id_documentation         Documentation parent Id
    * @param i_id_epis_documentation    Epis documentation Id        
    * @param i_nr_answered_questions    Nr of ansered questions or filled elements
    * @param o_error                    Error
    *
    * @return                          Scores
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           25-Mai-2011
    **********************************************************************************************/
    FUNCTION get_calculated_scores
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_scales_group       IN scales_group.id_scales_group%TYPE,
        i_id_scales             IN scales.id_scales%TYPE,
        i_id_documentation      IN documentation.id_documentation%TYPE,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_nr_answered_questions IN PLS_INTEGER
    ) RETURN t_tab_score_formulas IS
        l_error        t_error_out;
        l_doc_elements table_number;
    BEGIN
        --get doc_elements inserted in the current epis_documentation
        g_error := 'get doc_elements inserted in the current epis_documentation. i_id_epis_documentation: ' ||
                   i_id_epis_documentation;
        pk_alertlog.log_debug(g_error);
        SELECT edd.id_doc_element BULK COLLECT
          INTO l_doc_elements
          FROM epis_documentation_det edd
         WHERE edd.id_epis_documentation = i_id_epis_documentation;
    
        g_error := 'CALL get_calculated_scores.';
        pk_alertlog.log_debug(g_error);
        RETURN get_calculated_scores(i_lang                  => i_lang,
                                     i_prof                  => i_prof,
                                     i_id_episode            => i_id_episode,
                                     i_id_scales_group       => i_id_scales_group,
                                     i_id_scales             => i_id_scales,
                                     i_id_documentation      => i_id_documentation,
                                     i_doc_elements          => l_doc_elements,
                                     i_nr_answered_questions => i_nr_answered_questions);
    
    EXCEPTION
        WHEN g_exception THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_CALCULATED_SCORES',
                                              l_error);
            RETURN NULL;
    END get_calculated_scores;

    /********************************************************************************************
    *  Get the score (total or partial) as well as the class description and the complementary 
    *  formulas.
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_id_episode               Episode Id
    * @param i_id_scales_group          Scales group Id
    * @param i_id_scales                Scales Id 
    * @param i_id_documentation         Documentation parent Id
    * @param i_doc_elements             Doc elements Ids
    * @param i_values                   Values inserted by the user for each doc_element
    * @param i_flg_score_type           'P' - partial score; T - total score.
    * @param i_nr_answered_questions    Nr of ansered questions or filled elements
    * @param o_main_scores              Main scores results
    * @param o_descs                    Scales decritions and complementary formulas results.
    * @param o_error                    Error
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           25-Mai-2011
    **********************************************************************************************/
    FUNCTION get_score
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_scales_group       IN scales_group.id_scales_group%TYPE,
        i_id_scales             IN scales.id_scales%TYPE,
        i_id_documentation      IN documentation.id_documentation%TYPE,
        i_doc_elements          IN table_number,
        i_values                IN table_number,
        i_flg_score_type        IN VARCHAR2,
        i_nr_answered_questions IN PLS_INTEGER,
        o_main_scores           OUT pk_types.cursor_type,
        o_descs                 OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_formulas t_tab_score_formulas := t_tab_score_formulas();
    BEGIN
        g_error := 'CALL get_calculated_scores. i_id_episode: ' || i_id_episode || ' i_flg_score_type: ' ||
                   i_flg_score_type || ' i_id_scales_group: ' || i_id_scales_group || ' i_id_scales: ' || i_id_scales ||
                   ' i_id_documentation: ' || i_id_documentation;
        pk_alertlog.log_debug(g_error);
        l_formulas := get_calculated_scores(i_lang                  => i_lang,
                                            i_prof                  => i_prof,
                                            i_id_episode            => i_id_episode,
                                            i_id_scales_group       => i_id_scales_group,
                                            i_id_scales             => i_id_scales,
                                            i_id_documentation      => i_id_documentation,
                                            i_doc_elements          => i_doc_elements,
                                            i_nr_answered_questions => i_nr_answered_questions);
    
        g_error := 'OPEN O_MAIN_SCORES.';
        pk_alertlog.log_debug(g_error);
        OPEN o_main_scores FOR
            SELECT scr.description label,
                   round(scr.score_value, 2) score_value,
                   scr.id_scales_formula id_scales_formula,
                   scr.flg_visible
              FROM TABLE(l_formulas) scr
             WHERE scr.flg_formula_type IN (pk_scales_constant.g_formula_type_tm, pk_scales_constant.g_formula_type_pm)
               AND ((i_id_scales_group IS NOT NULL AND scr.id_scales_group = i_id_scales_group AND
                   scr.id_documentation IS NULL AND scr.id_doc_element IS NULL) OR
                   (i_id_documentation IS NOT NULL AND scr.id_documentation = i_id_documentation AND
                   scr.id_doc_element IS NULL) OR
                   (i_id_scales IS NOT NULL AND i_id_documentation IS NULL AND i_id_scales_group IS NULL AND
                   scr.id_scales = i_id_scales AND scr.id_documentation IS NULL AND scr.id_doc_element IS NULL AND
                   scr.id_scales_group IS NULL))
               AND scr.score_value IS NOT NULL;
    
        IF (i_flg_score_type = pk_scales_constant.g_flg_score_total_t)
        THEN
            g_error := 'CALL get_class_compl_descriptions';
            pk_alertlog.log_debug(g_error);
            IF NOT get_class_compl_descriptions(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_id_episode => i_id_episode,
                                                i_id_scales  => i_id_scales,
                                                i_formulas   => l_formulas,
                                                o_descs      => o_descs,
                                                o_error      => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_descs);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_main_scores);
            pk_types.open_my_cursor(o_descs);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_main_scores);
            pk_types.open_my_cursor(o_descs);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ELEMENTS_SCORE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_score;

    /********************************************************************************************
    *  Get the groups associated to a scale, or associated to the scales associated to a doc_area.
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info    
    * @param i_id_doc_area             Documentation Area ID        
    * @param i_scales                  Scales ID
    * @param o_groups                  Groups info
    * @param o_error                   Error message
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           05-Jul-2011
    **********************************************************************************************/
    FUNCTION get_groups
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        i_scales   IN scales.id_scales%TYPE,
        o_groups   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_GROUPS. i_doc_area: ' || i_doc_area || ' i_scales: ' || i_scales;
        pk_alertlog.log_debug(g_error);
        OPEN o_groups FOR
            SELECT sgr.id_scales_group, sgr.id_documentation, sgr.id_scales
              FROM scales_group_rel sgr
              JOIN documentation doc
                ON doc.id_documentation = sgr.id_documentation
             WHERE (sgr.id_scales = i_scales OR i_scales IS NULL)
               AND doc.id_doc_area = i_doc_area
               AND sgr.flg_available = pk_alert_constant.g_yes
            UNION ALL
            --it was requested by the flash layer to send also the scales as a group
            SELECT NULL id_scales_group, NULL id_documentation, i_scales id_scales
              FROM dual
             WHERE i_scales IS NOT NULL;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_groups);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_GROUPS',
                                              o_error);
            RETURN FALSE;
    END get_groups;

    /********************************************************************************************
    *  Calculates the nr of questions that had been answered by the user based on the selected 
    *  doc_elements
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info    
    * @param i_scores                  Scores info        
    * @param o_nr_questions            Nr of answered questions
    * @param o_error                   Error message
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           05-Jul-2011
    **********************************************************************************************/
    FUNCTION get_nr_answered_questions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_scores       IN t_tab_score_values,
        o_nr_questions OUT PLS_INTEGER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALC the nr of answered questions';
        pk_alertlog.log_debug(g_error);
        SELECT COUNT(1)
          INTO o_nr_questions
          FROM (SELECT DISTINCT de.id_documentation
                  FROM doc_element de
                 WHERE de.id_doc_element IN (SELECT /*+opt_estimate (table t rows=1)*/
                                              id_doc_element
                                               FROM TABLE(i_scores) t));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_NR_ANSWERED_QUESTIONS',
                                              o_error);
            RETURN FALSE;
    END get_nr_answered_questions;

    /********************************************************************************************
    *  Calculates the element that has the greater score. Returns the score of that element.
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info    
    * @param i_scores                  Scores info        
    * @param o_max_score               Maximun score
    * @param o_error                   Error message
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           05-Sep-2011
    **********************************************************************************************/
    FUNCTION get_max_score
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_scores    IN t_tab_score_values,
        o_max_score OUT scales_doc_value.value%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_scores_count PLS_INTEGER;
    BEGIN
        g_error := 'CALC the maximun score';
        pk_alertlog.log_debug(g_error);
        l_scores_count := i_scores.count;
    
        o_max_score := 0;
    
        FOR i IN 1 .. l_scores_count
        LOOP
            IF (i_scores(i).value > o_max_score)
            THEN
                o_max_score := i_scores(i).value;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_MAX_SCORE',
                                              o_error);
            RETURN FALSE;
    END get_max_score;

    /********************************************************************************************
    *  Get the scores of the elements associated to an doc_area, the groups and the scale.
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info    
    * @param i_id_doc_area             Documentation Area ID    
    * @param o_score                   New documentation ID
    * @param o_groups                  Groups info
    * @param o_id_scales               Scales identifier
    * @param o_error                   Error message
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           24-Mai-2011
    **********************************************************************************************/
    FUNCTION get_elements_score
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_doc_area        IN doc_area.id_doc_area%TYPE,
        i_id_doc_template IN doc_template.id_doc_template%TYPE,
        o_score           OUT pk_types.cursor_type,
        o_groups          OUT pk_types.cursor_type,
        o_id_scales       OUT scales.id_scales%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_SCORE. i_doc_area: ' || i_doc_area;
        pk_alertlog.log_debug(g_error);
        OPEN o_score FOR
            SELECT de.id_doc_element, pk_scales_formulas.round_number(i_lang, i_prof, sdv.value) score, doc.id_documentation
              FROM scales_doc_value sdv
             INNER JOIN doc_element de
                ON de.id_doc_element = sdv.id_doc_element
             INNER JOIN documentation doc
                ON doc.id_documentation = de.id_documentation
             INNER JOIN doc_template_area_doc dtad
                ON dtad.id_documentation = doc.id_documentation
             WHERE dtad.id_doc_area = i_doc_area
               AND dtad.id_doc_template = i_id_doc_template;
    
        g_error := 'CALL get_id_scales. i_doc_area: ' || i_doc_area;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_scales_core.get_id_scales(i_lang            => i_lang,
                                            i_prof            => i_prof,
                                            i_doc_area        => i_doc_area,
                                            i_id_doc_template => i_id_doc_template,
                                            o_id_scales       => o_id_scales,
                                            o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL get_groups. i_doc_area: ' || i_doc_area;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_scales_formulas.get_groups(i_lang     => i_lang,
                                             i_prof     => i_prof,
                                             i_doc_area => i_doc_area,
                                             i_scales   => o_id_scales,
                                             o_groups   => o_groups,
                                             o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_score);
            pk_types.open_my_cursor(o_groups);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ELEMENTS_SCORE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_elements_score;

BEGIN

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_scales_formulas;
/
