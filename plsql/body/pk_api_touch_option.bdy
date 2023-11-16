/*-- Last Change Revision: $Rev: 1857962 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-30 11:49:08 +0100 (seg, 30 jul 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_touch_option IS

    k_tch_opt_new  CONSTANT VARCHAR2(0010 CHAR) := pk_touch_option.g_flg_edition_type_new;
    k_tch_opt_edit CONSTANT VARCHAR2(0010 CHAR) := pk_touch_option.g_flg_edition_type_edit;
    g_other_exception EXCEPTION;

    FUNCTION iif
    (
        i_bool  IN BOOLEAN,
        i_true  IN VARCHAR2,
        i_false IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
    
        IF i_bool
        THEN
            RETURN i_true;
        ELSE
            RETURN i_false;
        END IF;
    
    END iif;

    -- map one or more doc_element internal_name to id_doc_element
    PROCEDURE map_doc_element
    (
        i_internal_name     IN table_varchar,
        i_doc_area          IN NUMBER,
        i_doc_template      IN NUMBER,
        o_tbl_element       OUT table_number,
        o_tbl_documentation OUT table_number
    ) IS
        tbl_element       table_number;
        tbl_documentation table_number;
    BEGIN
    
        SELECT de.id_doc_element, de.id_documentation
          BULK COLLECT
          INTO tbl_element, tbl_documentation
          FROM doc_element de
          JOIN documentation doc
            ON doc.id_documentation = de.id_documentation
          JOIN doc_template dt
            ON dt.id_doc_template = doc.id_doc_template
          JOIN (SELECT /*+ OPT_ESTIMATE(TABLE xtbl ROWS=1) */
                 rownum rn, column_value internal_name
                  FROM TABLE(i_internal_name) xtbl) dint
            ON dint.internal_name = de.internal_name
         WHERE doc.id_doc_area = i_doc_area
           AND doc.id_doc_template = i_doc_template
         ORDER BY dint.rn;
    
        o_tbl_documentation := tbl_documentation;
        o_tbl_element       := tbl_element;
    
    END map_doc_element;

    FUNCTION get_master_item
    (
        i_id_doc_element IN NUMBER,
        i_flg_type       IN VARCHAR2
    ) RETURN NUMBER IS
        l_master_item NUMBER;
    BEGIN
        BEGIN
            SELECT d.id_master_item
              INTO l_master_item
              FROM doc_element d
             WHERE d.id_doc_element = i_id_doc_element
               AND d.flg_type = i_flg_type;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_master_item := NULL;
        END;
    
        RETURN l_master_item;
    
    END get_master_item;

    FUNCTION get_vs_doc_element
    (
        i_id_doc_element IN NUMBER,
        i_flg_type       IN VARCHAR2
    ) RETURN NUMBER IS
        l_id_doc_element NUMBER;
    BEGIN
        BEGIN
            SELECT d.id_doc_element
              INTO l_id_doc_element
              FROM doc_element d
             WHERE d.id_doc_element = i_id_doc_element
               AND d.flg_type = i_flg_type;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_id_doc_element := NULL;
        END;
    
        RETURN l_id_doc_element;
    
    END get_vs_doc_element;

    PROCEDURE init_vs_array
    (
        i_tbl_doc_element IN table_number,
        o_tbl_tbl_vs      OUT table_number
        
    ) IS
        l_tbl_tbl_vs  table_number := table_number();
        l_master_item NUMBER;
    BEGIN
        -- mudar aqui para so fazer table_number (l_master_item)
        <<lup_thru_doc_elements>>
        FOR i IN 1 .. i_tbl_doc_element.count
        LOOP
            -- get master item for the VS elements
            l_master_item := get_master_item(i_id_doc_element => i_tbl_doc_element(i), i_flg_type => 'VS');
            IF l_master_item IS NOT NULL
            THEN
                l_tbl_tbl_vs.extend();
                l_tbl_tbl_vs(i) := l_master_item;
            ELSE
                l_tbl_tbl_vs.extend();
                l_tbl_tbl_vs(i) := NULL;
            END IF;
        END LOOP lup_thru_doc_elements;
    
        o_tbl_tbl_vs := l_tbl_tbl_vs;
    
    END init_vs_array;

    PROCEDURE set_vs_arrays
    (
        i_id_vital_sign     IN table_table_number,
        i_vs_value_list     IN table_table_number,
        i_vs_save_mode_list IN table_table_varchar,
        i_vs_uom_list       IN table_table_number,
        i_vs_scales_list    IN table_table_number,
        i_vs_date_list      IN table_table_varchar,
        o_id_vital_sign     OUT table_table_number,
        o_vs_value_list     OUT table_table_number,
        o_vs_save_mode_list OUT table_table_varchar,
        o_vs_uom_list       OUT table_table_number,
        o_vs_scales_list    OUT table_table_number,
        o_vs_date_list      OUT table_table_varchar
    ) IS
    
    BEGIN
    
        SELECT t.vital_sign, t.value_list, t.save_mode, t.uom_list, t.scales_list, t.date_list
          BULK COLLECT
          INTO o_id_vital_sign, o_vs_value_list, o_vs_save_mode_list, o_vs_uom_list, o_vs_scales_list, o_vs_date_list
          FROM (SELECT *
                  FROM (SELECT rownum rn, column_value vital_sign
                          FROM TABLE(i_id_vital_sign) t1) vs
                  JOIN (SELECT rownum rn, column_value value_list
                         FROM TABLE(i_vs_value_list) t2) vl
                    ON vl.rn = vs.rn
                  JOIN (SELECT rownum rn, column_value save_mode
                         FROM TABLE(i_vs_save_mode_list) t3) sm
                    ON sm.rn = vs.rn
                  JOIN (SELECT rownum rn, column_value uom_list
                         FROM TABLE(i_vs_uom_list) t4) ul
                    ON ul.rn = vs.rn
                  JOIN (SELECT rownum rn, column_value scales_list
                         FROM TABLE(i_vs_scales_list) t5) sl
                    ON sl.rn = vs.rn
                  JOIN (SELECT rownum rn, column_value date_list
                         FROM TABLE(i_vs_date_list) t6) dl
                    ON dl.rn = vs.rn
                 WHERE rownum > 0) t
         WHERE t.vital_sign IS NOT NULL;
    
    END set_vs_arrays;

    FUNCTION populate_number_array(i_array IN table_table_number) RETURN table_number IS
    
        li_array table_number := table_number();
        lo_array table_number := table_number();
    
    BEGIN
        <<lup_thru_array>>
        FOR i IN 1 .. i_array.count
        LOOP
            li_array := i_array(i);
            IF li_array.count < 2
               AND li_array(1) IS NOT NULL
            THEN
                lo_array.extend;
                lo_array(lo_array.last) := li_array(1);
            ELSIF li_array.count > 1
            THEN
                FOR j IN 1 .. li_array.count
                LOOP
                    IF li_array(j) IS NOT NULL
                    THEN
                        lo_array.extend;
                        lo_array(lo_array.last) := li_array(j);
                    END IF;
                END LOOP lup_thru_array;
            END IF;
        END LOOP;
    
        RETURN lo_array;
    
    END populate_number_array;

    FUNCTION populate_varchar_array(i_array IN table_table_varchar) RETURN table_varchar IS
    
        li_array table_varchar := table_varchar();
        lo_array table_varchar := table_varchar();
    
    BEGIN
    
        FOR i IN 1 .. i_array.count
        LOOP
            li_array := i_array(i);
            IF li_array.count < 2
               AND li_array(1) IS NOT NULL
            THEN
                lo_array.extend;
                lo_array(lo_array.last) := li_array(1);
            ELSIF li_array.count > 1
            THEN
                FOR j IN 1 .. li_array.count
                LOOP
                    lo_array.extend;
                    lo_array(lo_array.last) := li_array(j);
                END LOOP;
            END IF;
        END LOOP;
    
        RETURN lo_array;
    
    END populate_varchar_array;

    FUNCTION get_id_vs_read
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_vital_sign IN NUMBER,
        i_vs_date       IN VARCHAR2,
        i_vs_value      IN NUMBER
    ) RETURN NUMBER IS
        l_ret NUMBER;
    BEGIN
    
        BEGIN
            SELECT v.id_vital_sign_read
              INTO l_ret
              FROM vital_sign_read v
             WHERE v.id_vital_sign = i_id_vital_sign
               AND v.id_episode = i_id_episode
               AND v.value = i_vs_value
               AND pk_date_utils.compare_dates_tsz(i_prof,
                                                   v.dt_vital_sign_read_tstz,
                                                   pk_date_utils.get_string_tstz(i_lang, i_prof, i_vs_date, NULL)) = 'E';
        EXCEPTION
            WHEN no_data_found THEN
                l_ret := NULL;
        END;
    
        RETURN l_ret;
    
    END get_id_vs_read;

    /*Function that returns the id_doc_elements of the vital signs elements and also modifies the io_id_vital_sign list*/
    PROCEDURE map_all_vs_arrays
    (
        i_lang              IN language.id_language%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_prof              IN profissional,
        tbl_doc_element     IN table_number,
        i_id_vital_sign     IN table_table_number,
        i_vs_value_list     IN table_table_number,
        i_vs_uom_list       IN table_table_number,
        i_vs_scales_list    IN table_table_number,
        i_vs_date_list      IN table_table_varchar,
        i_vs_save_mode_list IN table_varchar,
        io_id_vital_sign    IN OUT table_number,
        o_vs_value_list     OUT table_number,
        o_vs_uom_list       OUT table_number,
        o_vs_scales_list    OUT table_number,
        o_vs_date_list      OUT table_varchar,
        o_vs_save_mode_list OUT table_varchar,
        o_vs_read_list      OUT table_number,
        tbl_doc_element_vs  OUT table_number
    ) IS
        l_tbl_doc_element_vs table_number := table_number();
        l_vs_doc_element     NUMBER;
        l_count              NUMBER := 0;
    
        --l_test NUMBER;
    
        l_temp_tbl_vs table_number;
        l_final_id_vs table_number := table_number();
    
        lo_vs_scales_list    table_number := table_number();
        lo_vs_uom_list       table_number := table_number();
        lo_vs_save_mode_list table_varchar := table_varchar();
        lo_vs_date_list      table_varchar := table_varchar();
        l_vs_read_list       table_number := table_number();
    BEGIN
    
        /*First: Manipulate the VS tbl_doc_element*/
        <<lup_thru_doc_elements>>
        FOR i IN 1 .. tbl_doc_element.count
        LOOP
            l_vs_doc_element := get_vs_doc_element(i_id_doc_element => tbl_doc_element(i), i_flg_type => 'VS');
            IF l_vs_doc_element IS NOT NULL
            THEN
                l_count := l_count + 1;
                l_tbl_doc_element_vs.extend();
                l_tbl_doc_element_vs(l_count) := l_vs_doc_element;
            
                -- in case it is a composed vital sign, it should replicate the id to the next position
                l_temp_tbl_vs := i_id_vital_sign(i);
                IF l_temp_tbl_vs.count > 1
                THEN
                    l_count := l_count + 1;
                    l_tbl_doc_element_vs.extend();
                    l_tbl_doc_element_vs(l_count) := l_vs_doc_element;
                END IF;
            END IF;
        END LOOP lup_thru_doc_elements;
    
        tbl_doc_element_vs := l_tbl_doc_element_vs;
        /*First: Manipulate the VS tbl_doc_element*/
    
        /*Second: Loop to compare the VS id lists (and populate o_vs_scales_list, o_vs_uom_list and o_vs_save_mode_list)*/
        /* loop two compare the two lists and only modify the io_id_vital_sign list*/
        <<lup_thru_vs>>
        FOR i IN 1 .. i_id_vital_sign.count
        LOOP
            l_temp_tbl_vs := i_id_vital_sign(i);
            IF l_temp_tbl_vs.count < 2
            THEN
                IF l_temp_tbl_vs(1) != io_id_vital_sign(i)
                THEN
                    l_final_id_vs.extend;
                    l_final_id_vs(l_final_id_vs.last) := l_temp_tbl_vs(1);
                
                    lo_vs_scales_list.extend;
                    lo_vs_scales_list(lo_vs_scales_list.last) := i_vs_scales_list(i) (1);
                
                    lo_vs_uom_list.extend;
                    lo_vs_uom_list(lo_vs_uom_list.last) := i_vs_uom_list(i) (1);
                
                    IF i_vs_save_mode_list(i) IS NOT NULL
                    THEN
                        lo_vs_save_mode_list.extend;
                        lo_vs_save_mode_list(lo_vs_save_mode_list.last) := i_vs_save_mode_list(i);
                    ELSE
                        lo_vs_save_mode_list.extend;
                        lo_vs_save_mode_list(lo_vs_save_mode_list.last) := 'N';
                    END IF;
                
                    lo_vs_date_list.extend;
                    lo_vs_date_list(lo_vs_date_list.last) := i_vs_date_list(i) (1);
                
                ELSIF l_temp_tbl_vs(1) IS NOT NULL
                THEN
                    l_final_id_vs.extend;
                    l_final_id_vs(l_final_id_vs.last) := l_temp_tbl_vs(1);
                
                    lo_vs_scales_list.extend;
                    lo_vs_scales_list(lo_vs_scales_list.last) := i_vs_scales_list(i) (1);
                
                    lo_vs_uom_list.extend;
                    lo_vs_uom_list(lo_vs_uom_list.last) := i_vs_uom_list(i) (1);
                
                    IF i_vs_save_mode_list(i) IS NOT NULL
                    THEN
                        lo_vs_save_mode_list.extend;
                        lo_vs_save_mode_list(lo_vs_save_mode_list.last) := i_vs_save_mode_list(i);
                    ELSE
                        lo_vs_save_mode_list.extend;
                        lo_vs_save_mode_list(lo_vs_save_mode_list.last) := 'N';
                    END IF;
                
                    lo_vs_date_list.extend;
                    lo_vs_date_list(lo_vs_date_list.last) := i_vs_date_list(i) (1);
                
                END IF;
            ELSE
                /* this means the vs is composed so we have to put the different values into the last positions of l_final_id_vs */
                FOR j IN 1 .. l_temp_tbl_vs.count
                LOOP
                    l_final_id_vs.extend;
                    l_final_id_vs(l_final_id_vs.last) := l_temp_tbl_vs(j);
                
                    lo_vs_scales_list.extend;
                    lo_vs_scales_list(lo_vs_scales_list.last) := i_vs_scales_list(i) (j);
                
                    lo_vs_uom_list.extend;
                    lo_vs_uom_list(lo_vs_uom_list.last) := i_vs_uom_list(i) (j);
                
                    IF i_vs_save_mode_list(i) IS NOT NULL
                    THEN
                        lo_vs_save_mode_list.extend;
                        lo_vs_save_mode_list(lo_vs_save_mode_list.last) := i_vs_save_mode_list(i);
                    ELSE
                        lo_vs_save_mode_list.extend;
                        lo_vs_save_mode_list(lo_vs_save_mode_list.last) := 'N';
                    END IF;
                
                    lo_vs_date_list.extend;
                    lo_vs_date_list(lo_vs_date_list.last) := i_vs_date_list(i) (j);
                END LOOP;
            END IF;
        END LOOP lup_thru_vs;
    
        io_id_vital_sign    := l_final_id_vs;
        o_vs_scales_list    := lo_vs_scales_list;
        o_vs_uom_list       := lo_vs_uom_list;
        o_vs_save_mode_list := lo_vs_save_mode_list;
        o_vs_date_list      := lo_vs_date_list;
        /* Second: Loop to compare the VS id lists (and populate o_vs_scales_list, o_vs_uom_list and o_vs_save_mode_list) */
    
        /*Third: populate the o_vs_value_list array */
        o_vs_value_list := populate_number_array(i_vs_value_list);
        /*Third: populate the o_vs_value_list array */
    
        /*Fourth: populate the o_vs_read_list array*/
        FOR i IN 1 .. l_final_id_vs.count
        LOOP
            l_vs_read_list.extend;
            l_vs_read_list(i) := get_id_vs_read(i_lang,
                                                i_prof,
                                                i_id_episode,
                                                l_final_id_vs(i),
                                                lo_vs_date_list(i),
                                                o_vs_value_list(i));
        END LOOP;
        o_vs_read_list := l_vs_read_list;
        /*Fourth: populate the o_vs_read_list array*/
    END map_all_vs_arrays;

    FUNCTION chk_doc_area_flg_score(i_id_doc_area IN doc_area.id_doc_area%TYPE) RETURN BOOLEAN IS
        l_ret       BOOLEAN;
        l_flg_score VARCHAR2(1);
    BEGIN
        l_ret := FALSE;
        BEGIN
            SELECT d.flg_score
              INTO l_flg_score
              FROM doc_area d
             WHERE d.id_doc_area = i_id_doc_area;
        EXCEPTION
            WHEN no_data_found THEN
                l_ret := NULL;
        END;
    
        IF l_flg_score = 'Y'
        THEN
            l_ret := TRUE;
        END IF;
    
        RETURN l_ret;
    
    END chk_doc_area_flg_score;

    FUNCTION is_vs(i_id_doc_element IN doc_element.id_doc_element%TYPE) RETURN BOOLEAN IS
        l_ret      BOOLEAN;
        l_flg_type VARCHAR(24);
    BEGIN
        BEGIN
            SELECT d.flg_type
              INTO l_flg_type
              FROM doc_element d
             WHERE d.id_doc_element = i_id_doc_element;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_ret := FALSE;
        END;
    
        l_ret := l_flg_type = 'VS';
    
        RETURN l_ret;
    
    END is_vs;

    -- map_doc_element_crit
    FUNCTION map_all_doc_element_crit
    (
        i_doc_area         IN NUMBER,
        i_doc_template     IN NUMBER,
        i_tbl_element      IN table_number,
        i_tbl_doc_criteria IN table_number
    ) RETURN table_number IS
        tbl_return table_number;
        k_fixed_criteria CONSTANT NUMBER := 6;
    BEGIN
    
        SELECT nvl(dec.id_doc_element_crit, dec2.id_doc_element_crit)
          BULK COLLECT
          INTO tbl_return
          FROM doc_element_crit DEC
         RIGHT JOIN (SELECT /*+ OPT_ESTIMATE(TABLE xdintx ROWS=1) */
                      *
                       FROM (SELECT d1.id_doc_element, d2.id_doc_criteria, d1.rn rn_element, d2.rn rn_crit
                               FROM (SELECT /*+ OPT_ESTIMATE(TABLE xtbl1 ROWS=1) */
                                      rownum rn, column_value id_doc_element
                                       FROM TABLE(i_tbl_element) xtbl1) d1
                               LEFT JOIN (SELECT /*+ OPT_ESTIMATE(TABLE xtbl2 ROWS=1) */
                                          rownum rn, column_value id_doc_criteria
                                           FROM TABLE(i_tbl_doc_criteria) xtbl2) d2
                                 ON d2.rn = d1.rn) dintx) dint
            ON dint.id_doc_element = dec.id_doc_element
           AND dint.id_doc_criteria = dec.id_doc_criteria
          JOIN doc_element de
            ON de.id_doc_element = dint.id_doc_element
          JOIN documentation doc
            ON doc.id_documentation = de.id_documentation
          LEFT JOIN doc_element_crit dec2
            ON dec2.id_doc_element = dint.id_doc_element
           AND dec2.id_doc_criteria = k_fixed_criteria
         WHERE doc.id_doc_area = i_doc_area
           AND doc.id_doc_template = i_doc_template
         ORDER BY rn_element;
    
        RETURN tbl_return;
    
    END map_all_doc_element_crit;

    -- ***************************    
    FUNCTION ins_template
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_dt_creation           IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_vs_element_list       IN table_number DEFAULT NULL,
        i_vs_save_mode_list     IN table_varchar DEFAULT NULL,
        i_vs_list               IN table_number DEFAULT NULL,
        i_vs_value_list         IN table_number DEFAULT NULL,
        i_vs_uom_list           IN table_number DEFAULT NULL,
        i_vs_scales_list        IN table_number DEFAULT NULL,
        i_vs_date_list          IN table_varchar DEFAULT NULL,
        i_vs_read_list          IN table_number DEFAULT NULL,
        i_id_edit_reason        IN table_number DEFAULT NULL,
        i_notes_edit            IN table_clob DEFAULT NULL,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_cat_type VARCHAR2(0100 CHAR);
        l_bool          BOOLEAN;
    
    BEGIN
    
        l_bool := pk_touch_option.set_epis_document_internal(i_lang                  => i_lang,
                                                             i_prof                  => i_prof,
                                                             i_prof_cat_type         => l_prof_cat_type,
                                                             i_epis                  => i_episode,
                                                             i_doc_area              => i_doc_area,
                                                             i_doc_template          => i_doc_template,
                                                             i_epis_documentation    => NULL,
                                                             i_flg_type              => k_tch_opt_new,
                                                             i_id_documentation      => i_id_documentation,
                                                             i_id_doc_element        => i_id_doc_element,
                                                             i_id_doc_element_crit   => i_id_doc_element_crit,
                                                             i_value                 => i_value,
                                                             i_dt_creation           => i_dt_creation,
                                                             i_notes                 => i_notes,
                                                             i_id_epis_complaint     => NULL,
                                                             i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                             i_epis_context          => NULL,
                                                             i_vs_element_list       => i_vs_element_list,
                                                             i_vs_save_mode_list     => i_vs_save_mode_list,
                                                             i_vs_list               => i_vs_list,
                                                             i_vs_value_list         => i_vs_value_list,
                                                             i_vs_uom_list           => i_vs_uom_list,
                                                             i_vs_scales_list        => i_vs_scales_list,
                                                             i_vs_date_list          => i_vs_date_list,
                                                             i_vs_read_list          => i_vs_read_list,
                                                             o_epis_documentation    => o_epis_documentation,
                                                             o_error                 => o_error);
    
        RETURN l_bool;
    
    END ins_template;

    -- ***********************************
    FUNCTION edit_template
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_vs_element_list       IN table_number DEFAULT NULL,
        i_vs_save_mode_list     IN table_varchar DEFAULT NULL,
        i_vs_list               IN table_number DEFAULT NULL,
        i_vs_value_list         IN table_number DEFAULT NULL,
        i_vs_uom_list           IN table_number DEFAULT NULL,
        i_vs_scales_list        IN table_number DEFAULT NULL,
        i_vs_date_list          IN table_varchar DEFAULT NULL,
        i_vs_read_list          IN table_number DEFAULT NULL,
        i_id_edit_reason        IN table_number DEFAULT NULL,
        i_notes_edit            IN table_clob DEFAULT NULL,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_bool BOOLEAN;
    
    BEGIN
    
        l_bool := pk_touch_option.set_epis_document_internal(i_lang                  => i_lang,
                                                             i_prof                  => i_prof,
                                                             i_prof_cat_type         => i_prof_cat_type,
                                                             i_epis                  => i_episode,
                                                             i_doc_area              => i_doc_area,
                                                             i_doc_template          => i_doc_template,
                                                             i_epis_documentation    => i_epis_documentation,
                                                             i_flg_type              => k_tch_opt_edit,
                                                             i_id_documentation      => i_id_documentation,
                                                             i_id_doc_element        => i_id_doc_element,
                                                             i_id_doc_element_crit   => i_id_doc_element_crit,
                                                             i_value                 => i_value,
                                                             i_notes                 => i_notes,
                                                             i_id_epis_complaint     => NULL,
                                                             i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                             i_epis_context          => NULL,
                                                             i_vs_element_list       => i_vs_element_list,
                                                             i_vs_save_mode_list     => i_vs_save_mode_list,
                                                             i_vs_list               => i_vs_list,
                                                             i_vs_value_list         => i_vs_value_list,
                                                             i_vs_uom_list           => i_vs_uom_list,
                                                             i_vs_scales_list        => i_vs_scales_list,
                                                             i_vs_date_list          => i_vs_date_list,
                                                             i_vs_read_list          => i_vs_read_list,
                                                             i_id_edit_reason        => i_id_edit_reason,
                                                             i_notes_edit            => i_notes_edit,
                                                             o_epis_documentation    => o_epis_documentation,
                                                             o_error                 => o_error);
    
        RETURN l_bool;
    
    END edit_template;

    FUNCTION set_template
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_dt_creation           IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_vs_element_list       IN table_number DEFAULT NULL,
        i_vs_save_mode_list     IN table_varchar DEFAULT NULL,
        i_vs_list               IN table_number DEFAULT NULL,
        i_vs_value_list         IN table_number DEFAULT NULL,
        i_vs_uom_list           IN table_number DEFAULT NULL,
        i_vs_scales_list        IN table_number DEFAULT NULL,
        i_vs_date_list          IN table_varchar DEFAULT NULL,
        i_vs_read_list          IN table_number DEFAULT NULL,
        i_id_edit_reason        IN table_number DEFAULT NULL,
        i_notes_edit            IN table_clob DEFAULT NULL,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof_cat_type      VARCHAR2(0100 CHAR);
        l_bool               BOOLEAN;
        l_epis_documentation NUMBER := i_epis_documentation;
        l_flg_type           VARCHAR2(0010 CHAR);
    BEGIN
    
        l_prof_cat_type := pk_prof_utils.get_category(i_lang, i_prof);
    
        l_flg_type := iif(l_epis_documentation IS NOT NULL, k_tch_opt_edit, k_tch_opt_new);
    
        CASE l_flg_type
            WHEN k_tch_opt_new THEN
            
                l_bool := ins_template(i_lang => i_lang,
                                       i_prof => i_prof,
                                       --i_prof_cat_type         => l_prof_cat_type,
                                       i_episode               => i_episode,
                                       i_doc_area              => i_doc_area,
                                       i_doc_template          => i_doc_template,
                                       i_id_documentation      => i_id_documentation,
                                       i_id_doc_element        => i_id_doc_element,
                                       i_id_doc_element_crit   => i_id_doc_element_crit,
                                       i_value                 => i_value,
                                       i_notes                 => i_notes,
                                       i_id_doc_element_qualif => i_id_doc_element_qualif,
                                       i_dt_creation           => i_dt_creation,
                                       i_vs_element_list       => i_vs_element_list,
                                       i_vs_save_mode_list     => i_vs_save_mode_list,
                                       i_vs_list               => i_vs_list,
                                       i_vs_value_list         => i_vs_value_list,
                                       i_vs_uom_list           => i_vs_uom_list,
                                       i_vs_scales_list        => i_vs_scales_list,
                                       i_vs_date_list          => i_vs_date_list,
                                       i_vs_read_list          => i_vs_read_list,
                                       i_id_edit_reason        => i_id_edit_reason,
                                       i_notes_edit            => i_notes_edit,
                                       o_epis_documentation    => o_epis_documentation,
                                       o_error                 => o_error);
            
            WHEN k_tch_opt_edit THEN
            
                l_bool := edit_template(i_lang                  => i_lang,
                                        i_prof                  => i_prof,
                                        i_prof_cat_type         => l_prof_cat_type,
                                        i_episode               => i_episode,
                                        i_doc_area              => i_doc_area,
                                        i_doc_template          => i_doc_template,
                                        i_epis_documentation    => l_epis_documentation,
                                        i_id_documentation      => i_id_documentation,
                                        i_id_doc_element        => i_id_doc_element,
                                        i_id_doc_element_crit   => i_id_doc_element_crit,
                                        i_value                 => i_value,
                                        i_notes                 => i_notes,
                                        i_id_doc_element_qualif => i_id_doc_element_qualif,
                                        i_vs_element_list       => i_vs_element_list,
                                        i_vs_save_mode_list     => i_vs_save_mode_list,
                                        i_vs_list               => i_vs_list,
                                        i_vs_value_list         => i_vs_value_list,
                                        i_vs_uom_list           => i_vs_uom_list,
                                        i_vs_scales_list        => i_vs_scales_list,
                                        i_vs_date_list          => i_vs_date_list,
                                        i_vs_read_list          => i_vs_read_list,
                                        i_id_edit_reason        => i_id_edit_reason,
                                        i_notes_edit            => i_notes_edit,
                                        o_epis_documentation    => o_epis_documentation,
                                        o_error                 => o_error);
            
        END CASE;
    
        RETURN l_bool;
    
    END set_template;

    -- ****************************
    -- Update dt_criation of given epis_documentation
    -- ****************************
    FUNCTION set_dt_creation
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_dt   IN VARCHAR2
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        l_dt_creation epis_documentation.dt_creation_tstz%TYPE;
    BEGIN
    
        l_dt_creation := current_timestamp;
    
        IF i_dt IS NOT NULL
        THEN
        
            l_dt_creation := pk_date_utils. get_string_tstz(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_timestamp => i_dt,
                                                            i_timezone  => NULL,
                                                            i_mask      => pk_date_utils.g_dateformat);
        
        END IF;
    
        RETURN l_dt_creation;
    
    END set_dt_creation;

    -- ****************************
    -- Update dt_Cancel of given epis_documentation
    -- ****************************
    PROCEDURE set_dt_cancel
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_epis_documentation IN NUMBER,
        i_dt                 IN VARCHAR2
    ) IS
        l_dt_cancel epis_documentation.dt_cancel_tstz%TYPE;
    BEGIN
    
        IF i_dt IS NOT NULL
        THEN
        
            l_dt_cancel := pk_date_utils. get_string_tstz(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_timestamp => i_dt,
                                                          i_timezone  => NULL,
                                                          i_mask      => pk_date_utils.g_dateformat);
        
            UPDATE epis_documentation
               SET dt_cancel_tstz = l_dt_cancel
             WHERE id_epis_documentation = i_epis_documentation;
        
        END IF;
    
    END set_dt_cancel;

    /*************************************************************************/
    FUNCTION init_qualif_array
    (
        i_count                 NUMBER,
        i_id_doc_element_qualif table_table_number
    ) RETURN table_table_number IS
        l_tmp table_table_number := table_table_number();
    BEGIN
    
        IF NOT i_id_doc_element_qualif.exists(1)
        THEN
            l_tmp.extend(i_count);
            FOR i IN 1 .. i_count
            LOOP
                l_tmp(i) := table_number();
            END LOOP;
        
            RETURN l_tmp;
        ELSE
            RETURN i_id_doc_element_qualif;
        END IF;
    
    END init_qualif_array;
    /*************************************************************************/

    -- ****************************
    -- map values and set_Template
    -- ****************************
    FUNCTION map_n_set_template
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_doc_element_name      IN table_varchar,
        i_tbl_doc_criteria      IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation.notes%TYPE,
        i_dt_creation           IN VARCHAR2,
        i_id_doc_element_qualif IN table_table_number,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        tbl_doc_element         table_number := table_number();
        tbl_documentation       table_number := table_number();
        tbl_doc_element_crit    table_number := table_number();
        l_id_doc_element_qualif table_table_number := table_table_number();
    
        l_bool       BOOLEAN;
        l_bool_score BOOLEAN;
    
        l_epis_documentation epis_documentation.id_epis_documentation%TYPE;
        l_dt_creation        TIMESTAMP WITH LOCAL TIME ZONE;
    
        o_id_epis_scales_score table_number;
    
    BEGIN
    
        map_doc_element(i_internal_name     => i_doc_element_name,
                        i_doc_area          => i_doc_area,
                        i_doc_template      => i_doc_template,
                        o_tbl_element       => tbl_doc_element,
                        o_tbl_documentation => tbl_documentation);
    
        l_dt_creation := set_dt_creation(i_lang => i_lang, i_prof => i_prof, i_dt => i_dt_creation);
    
        tbl_doc_element_crit := map_all_doc_element_crit(i_doc_area         => i_doc_area,
                                                         i_doc_template     => i_doc_template,
                                                         i_tbl_element      => tbl_doc_element,
                                                         i_tbl_doc_criteria => i_tbl_doc_criteria);
    
        l_id_doc_element_qualif := init_qualif_array(i_count                 => tbl_doc_element.count,
                                                     i_id_doc_element_qualif => i_id_doc_element_qualif);
    
        IF pk_summary_page.is_doc_area_in_summary_page(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_id_doc_area     => i_doc_area,
                                                       i_id_summary_page => pk_advanced_directives.g_summ_page_adv_dir) =
           pk_alert_constant.g_yes
        THEN
            l_bool := pk_advanced_directives.set_advance_directive(i_lang                  => i_lang,
                                                                   i_prof                  => i_prof,
                                                                   i_prof_cat_type         => pk_prof_utils.get_category(i_lang,
                                                                                                                         i_prof),
                                                                   i_epis                  => i_episode,
                                                                   i_doc_area              => i_doc_area,
                                                                   i_doc_template          => i_doc_template,
                                                                   i_epis_documentation    => i_epis_documentation,
                                                                   i_flg_type              => iif(l_epis_documentation IS NOT NULL,
                                                                                                  k_tch_opt_edit,
                                                                                                  k_tch_opt_new),
                                                                   i_id_documentation      => tbl_documentation,
                                                                   i_id_doc_element        => tbl_doc_element,
                                                                   i_id_doc_element_crit   => tbl_doc_element_crit,
                                                                   i_value                 => i_value,
                                                                   i_notes                 => i_notes,
                                                                   i_id_doc_element_qualif => l_id_doc_element_qualif,
                                                                   i_epis_context          => NULL,
                                                                   o_epis_documentation    => l_epis_documentation,
                                                                   o_error                 => o_error);
        ELSE
            l_bool := set_template(i_lang                  => i_lang,
                                   i_prof                  => i_prof,
                                   i_episode               => i_episode,
                                   i_doc_area              => i_doc_area,
                                   i_doc_template          => i_doc_template,
                                   i_epis_documentation    => i_epis_documentation,
                                   i_id_documentation      => tbl_documentation,
                                   i_id_doc_element        => tbl_doc_element,
                                   i_id_doc_element_crit   => tbl_doc_element_crit,
                                   i_value                 => i_value,
                                   i_notes                 => i_notes,
                                   i_id_doc_element_qualif => l_id_doc_element_qualif,
                                   i_dt_creation           => l_dt_creation,
                                   o_epis_documentation    => l_epis_documentation,
                                   o_error                 => o_error);
        END IF;
    
        IF l_bool
           AND chk_doc_area_flg_score(i_id_doc_area => i_doc_area)
        THEN
        
            l_bool_score := get_all_score(i_lang                  => i_lang,
                                          i_prof                  => i_prof,
                                          i_doc_area              => i_doc_area,
                                          i_doc_template          => i_doc_template,
                                          i_id_episode            => i_episode,
                                          i_id_epis_documentation => l_epis_documentation,
                                          i_id_scales_group       => NULL,
                                          i_id_documentation      => NULL,
                                          i_doc_elements          => tbl_doc_element,
                                          i_values                => NULL,
                                          i_flg_score_type        => 'T',
                                          i_nr_answered_questions => NULL,
                                          o_id_epis_scales_score  => o_id_epis_scales_score,
                                          o_error                 => o_error);
        END IF;
    
        o_epis_documentation := l_epis_documentation;
    
        RETURN l_bool;
    
    END map_n_set_template;

    -- ****************************
    -- map values and set_Template FULL
    -- ****************************
    FUNCTION map_n_set_template_vital_sign
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_doc_element_name      IN table_varchar,
        i_tbl_doc_criteria      IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation.notes%TYPE,
        i_dt_creation           IN VARCHAR2,
        i_id_doc_element_qualif IN table_table_number DEFAULT NULL,
        i_id_vital_sign         IN table_table_number DEFAULT NULL,
        i_vs_value_list         IN table_table_number DEFAULT NULL,
        i_vs_save_mode_list     IN table_varchar DEFAULT NULL,
        i_vs_uom_list           IN table_table_number DEFAULT NULL,
        i_vs_scales_list        IN table_table_number DEFAULT NULL,
        i_vs_date_list          IN table_table_varchar DEFAULT NULL,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        tbl_doc_element      table_number := table_number();
        tbl_doc_element_vs   table_number;
        tbl_documentation    table_number := table_number();
        tbl_doc_element_crit table_number := table_number();
    
        l_id_vital_sign table_number;
    
        l_id_doc_element_qualif table_table_number := table_table_number();
        l_dt_creation           TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_vs_value_list     table_number;
        l_vs_uom_list       table_number;
        l_vs_scales_list    table_number;
        l_vs_date_list      table_varchar;
        l_vs_save_mode_list table_varchar;
    
        l_vs_read_list table_number;
    
        l_epis_documentation   epis_documentation.id_epis_documentation%TYPE;
        o_id_epis_scales_score table_number;
    
        l_bool       BOOLEAN;
        l_bool_score BOOLEAN;
    
    BEGIN
    
        /*Populates a list (tbl_doc_element) with the id's doc element considering doc_area, id_doc_template and internal name
        received by parameter*/
        map_doc_element(i_internal_name     => i_doc_element_name,
                        i_doc_area          => i_doc_area,
                        i_doc_template      => i_doc_template,
                        o_tbl_element       => tbl_doc_element,
                        o_tbl_documentation => tbl_documentation);
    
        IF i_id_vital_sign IS NOT NULL
        THEN
            /*Initializes a list with the id_vital_sign of the column doc_element.id_master_item (this is done because the id_vital_sign list
            can contain null values)*/
        
            l_id_vital_sign := table_number();
            init_vs_array(i_tbl_doc_element => tbl_doc_element, o_tbl_tbl_vs => l_id_vital_sign);
        
            /*Initialize a list with the id_doc_element of the vital sign elements of the tbl_doc_element list. It also modifies
            l_id_vital_sign list to consider the non null elements of the id_vital_sign list*/
            tbl_doc_element_vs  := table_number();
            l_vs_value_list     := table_number();
            l_vs_uom_list       := table_number();
            l_vs_scales_list    := table_number();
            l_vs_date_list      := table_varchar();
            l_vs_save_mode_list := table_varchar();
            l_vs_read_list      := table_number();
        
            map_all_vs_arrays(i_lang              => i_lang,
                              i_id_episode        => i_episode,
                              i_prof              => i_prof,
                              tbl_doc_element     => tbl_doc_element,
                              i_id_vital_sign     => i_id_vital_sign,
                              i_vs_value_list     => i_vs_value_list,
                              i_vs_uom_list       => i_vs_uom_list,
                              i_vs_scales_list    => i_vs_scales_list,
                              i_vs_date_list      => i_vs_date_list,
                              i_vs_save_mode_list => i_vs_save_mode_list,
                              io_id_vital_sign    => l_id_vital_sign,
                              o_vs_value_list     => l_vs_value_list,
                              o_vs_uom_list       => l_vs_uom_list,
                              o_vs_scales_list    => l_vs_scales_list,
                              o_vs_date_list      => l_vs_date_list,
                              o_vs_save_mode_list => l_vs_save_mode_list,
                              o_vs_read_list      => l_vs_read_list,
                              tbl_doc_element_vs  => tbl_doc_element_vs);
        END IF;
    
        /*Set dt_creation format. In case of i_dt_creation is null, it will consider current_timestamp*/
        l_dt_creation := set_dt_creation(i_lang => i_lang, i_prof => i_prof, i_dt => i_dt_creation);
    
        tbl_doc_element_crit := map_all_doc_element_crit(i_doc_area         => i_doc_area,
                                                         i_doc_template     => i_doc_template,
                                                         i_tbl_element      => tbl_doc_element,
                                                         i_tbl_doc_criteria => i_tbl_doc_criteria);
    
        l_id_doc_element_qualif := init_qualif_array(i_count                 => tbl_doc_element.count,
                                                     i_id_doc_element_qualif => i_id_doc_element_qualif);
    
        IF pk_summary_page.is_doc_area_in_summary_page(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_id_doc_area     => i_doc_area,
                                                       i_id_summary_page => pk_advanced_directives.g_summ_page_adv_dir) =
           pk_alert_constant.g_yes
        THEN
            l_bool := pk_advanced_directives.set_advance_directive(i_lang                  => i_lang,
                                                                   i_prof                  => i_prof,
                                                                   i_prof_cat_type         => pk_prof_utils.get_category(i_lang,
                                                                                                                         i_prof),
                                                                   i_epis                  => i_episode,
                                                                   i_doc_area              => i_doc_area,
                                                                   i_doc_template          => i_doc_template,
                                                                   i_epis_documentation    => i_epis_documentation,
                                                                   i_flg_type              => iif(l_epis_documentation IS NOT NULL,
                                                                                                  k_tch_opt_edit,
                                                                                                  k_tch_opt_new),
                                                                   i_id_documentation      => tbl_documentation,
                                                                   i_id_doc_element        => tbl_doc_element,
                                                                   i_id_doc_element_crit   => tbl_doc_element_crit,
                                                                   i_value                 => i_value,
                                                                   i_notes                 => i_notes,
                                                                   i_id_doc_element_qualif => l_id_doc_element_qualif,
                                                                   i_epis_context          => NULL,
                                                                   o_epis_documentation    => l_epis_documentation,
                                                                   o_error                 => o_error);
        ELSE
            l_bool := set_template(i_lang                  => i_lang,
                                   i_prof                  => i_prof,
                                   i_episode               => i_episode,
                                   i_doc_area              => i_doc_area,
                                   i_doc_template          => i_doc_template,
                                   i_epis_documentation    => i_epis_documentation,
                                   i_id_documentation      => tbl_documentation,
                                   i_id_doc_element        => tbl_doc_element,
                                   i_id_doc_element_crit   => tbl_doc_element_crit,
                                   i_value                 => i_value,
                                   i_notes                 => i_notes,
                                   i_id_doc_element_qualif => l_id_doc_element_qualif,
                                   i_dt_creation           => l_dt_creation,
                                   i_vs_element_list       => tbl_doc_element_vs,
                                   i_vs_save_mode_list     => l_vs_save_mode_list,
                                   i_vs_list               => l_id_vital_sign,
                                   i_vs_value_list         => l_vs_value_list,
                                   i_vs_uom_list           => l_vs_uom_list,
                                   i_vs_scales_list        => l_vs_scales_list,
                                   i_vs_date_list          => l_vs_date_list,
                                   i_vs_read_list          => l_vs_read_list,
                                   i_id_edit_reason        => NULL,
                                   i_notes_edit            => NULL,
                                   o_epis_documentation    => l_epis_documentation,
                                   o_error                 => o_error);
        END IF;
    
        IF l_bool
           AND chk_doc_area_flg_score(i_id_doc_area => i_doc_area)
        THEN
        
            l_bool_score := get_all_score(i_lang                  => i_lang,
                                          i_prof                  => i_prof,
                                          i_doc_area              => i_doc_area,
                                          i_doc_template          => i_doc_template,
                                          i_id_episode            => i_episode,
                                          i_id_epis_documentation => l_epis_documentation,
                                          i_id_scales_group       => NULL,
                                          i_id_documentation      => NULL,
                                          i_doc_elements          => tbl_doc_element,
                                          i_values                => NULL,
                                          i_flg_score_type        => 'T',
                                          i_nr_answered_questions => NULL,
                                          o_id_epis_scales_score  => o_id_epis_scales_score,
                                          o_error                 => o_error);
        END IF;
    
        o_epis_documentation := l_epis_documentation;
        RETURN l_bool;
    
    END map_n_set_template_vital_sign;

    /********************************************************************************************
    * Returns the value of specific elements from last documentation for an area, episode and template
    *
    * @param i_lang                Language ID
    * @param i_prof                Professional, software and institution ids
    * @param i_episode             Episode ID
    * @param i_doc_area            Area ID where check if registers were done
    * @param i_doc_template        (Optional) Template ID. Null = All templates
    * @param i_table_element_keys  Array of elements keys to retrieve their values
    * @param i_key_type            Type of key (ID, Internal Name, ID Content, etc)
    * @param o_last_epis_doc       Last documentation ID
    * @param o_last_date_epis_doc  Date of last epis documentation
    * @param o_element_values      Element values
    * @param o_error               Error info
    *
    * @return                      true or false on success or error
    *
    * @value i_key_type  {*} 'K' Element's key (id_doc_element) {*} 'N' Element's internal name
    *
    * @autor                       Ariel Machado
    * @version                     1.0
    * @since                       2009/03/19
    **********************************************************************************************/
    FUNCTION intf_last_doc_area_elem_values
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_doc_template       IN doc_template.id_doc_template%TYPE DEFAULT NULL,
        i_table_element_keys IN table_varchar,
        i_key_type           IN VARCHAR2,
        o_last_epis_doc      OUT epis_documentation.id_epis_documentation%TYPE,
        o_last_date_epis_doc OUT epis_documentation.dt_creation_tstz%TYPE,
        o_element_values     OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_touch_option.get_last_doc_area_elem_values(i_lang,
                                                             i_prof,
                                                             i_episode,
                                                             i_doc_area,
                                                             i_doc_template,
                                                             i_table_element_keys,
                                                             i_key_type,
                                                             o_last_epis_doc,
                                                             o_last_date_epis_doc,
                                                             o_element_values,
                                                             o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'INTF_LAST_DOC_AREA_ELEM_VALUES');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RAISE; --Raise in order to notify "external" application that are using this function
                RETURN l_ret;
            END;
    END intf_last_doc_area_elem_values;

    -- Cancelamento de templates
    FUNCTION cancel_template
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_epis_documentation IN NUMBER,
        i_cancel_reason      IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel       IN VARCHAR2,
        i_dt_cancel          IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool      BOOLEAN := TRUE;
        l_flg_show  VARCHAR2(1000 CHAR);
        l_msg_title VARCHAR2(1000 CHAR);
        l_msg_text  VARCHAR2(1000 CHAR);
        l_button    VARCHAR2(1000 CHAR);
    BEGIN
    
        IF i_epis_documentation IS NOT NULL
        THEN
        
            l_bool := pk_touch_option.cancel_epis_documentation(i_lang          => i_lang,
                                                                i_prof          => i_prof,
                                                                i_id_epis_doc   => i_epis_documentation,
                                                                i_notes         => i_notes_cancel,
                                                                i_test          => pk_alert_constant.g_no,
                                                                i_cancel_reason => i_cancel_reason,
                                                                o_flg_show      => l_flg_show,
                                                                o_msg_title     => l_msg_title,
                                                                o_msg_text      => l_msg_text,
                                                                o_button        => l_button,
                                                                o_error         => o_error);
        
            set_dt_cancel(i_lang               => i_lang,
                          i_prof               => i_prof,
                          i_epis_documentation => i_epis_documentation,
                          i_dt                 => i_dt_cancel);
        
        END IF;
    
        RETURN l_bool;
    
    END cancel_template;

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
        o_score_value           OUT VARCHAR2,
        o_id_scales_formula     OUT NUMBER,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool              BOOLEAN;
        l_label             VARCHAR2(4000);
        l_score_value       VARCHAR2(4000);
        l_id_scales_formula NUMBER;
        l_flg_visible       VARCHAR2(0010 CHAR);
    
        l_main_scores pk_types.cursor_type;
        l_descs       pk_types.cursor_type;
    BEGIN
    
        l_bool := pk_inp_nurse.get_score(i_lang                  => i_lang,
                                         i_prof                  => i_prof,
                                         i_id_episode            => i_id_episode,
                                         i_id_scales_group       => i_id_scales_group,
                                         i_id_scales             => i_id_scales,
                                         i_id_documentation      => i_id_documentation,
                                         i_doc_elements          => i_doc_elements,
                                         i_values                => i_values,
                                         i_flg_score_type        => i_flg_score_type,
                                         i_nr_answered_questions => i_nr_answered_questions,
                                         o_main_scores           => l_main_scores,
                                         o_descs                 => l_descs,
                                         o_error                 => o_error);
    
        IF l_bool
        THEN
        
            FETCH l_main_scores
                INTO l_label, l_score_value, l_id_scales_formula, l_flg_visible;
            CLOSE l_main_scores;
        
        END IF;
    
        o_score_value       := l_score_value;
        o_id_scales_formula := l_id_scales_formula;
        RETURN l_bool;
    
    END get_score;

    FUNCTION get_all_score
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_id_scales_group       IN scales_group.id_scales_group%TYPE,
        i_id_documentation      IN documentation.id_documentation%TYPE,
        i_doc_elements          IN table_number,
        i_values                IN table_number,
        i_flg_score_type        IN VARCHAR2,
        i_nr_answered_questions IN PLS_INTEGER,
        o_id_epis_scales_score  OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_score_value      VARCHAR2(4000); -- table_varchar?
        l_id_score_formula NUMBER; -- table_number?
        l_bool             BOOLEAN;
    
        l_id_scale scales.id_scales%TYPE;
        my_exception EXCEPTION;
    BEGIN
    
        l_bool := pk_scales_core.get_id_scales(i_lang            => i_lang,
                                               i_prof            => i_prof,
                                               i_doc_area        => i_doc_area,
                                               i_id_doc_template => i_doc_template,
                                               o_id_scales       => l_id_scale,
                                               o_error           => o_error);
    
        IF l_bool
        THEN
            l_bool := get_score(i_lang                  => i_lang,
                                i_prof                  => i_prof,
                                i_id_episode            => i_id_episode,
                                i_id_scales_group       => i_id_scales_group,
                                i_id_scales             => l_id_scale,
                                i_id_documentation      => i_id_documentation,
                                i_doc_elements          => i_doc_elements,
                                i_values                => i_values,
                                i_flg_score_type        => i_flg_score_type,
                                i_nr_answered_questions => i_nr_answered_questions,
                                o_score_value           => l_score_value,
                                o_id_scales_formula     => l_id_score_formula,
                                o_error                 => o_error);
        ELSE
            RAISE my_exception;
        END IF;
    
        IF l_bool
        THEN
            l_bool := pk_scales_core.set_epis_scales_score(i_lang                 => i_lang,
                                                           i_prof                 => i_prof,
                                                           i_id_episode           => i_id_episode,
                                                           i_id_epis_doc_old      => NULL,
                                                           i_id_epis_doc_new      => i_id_epis_documentation,
                                                           i_flags                => table_varchar(i_flg_score_type),
                                                           i_ids                  => table_number(l_id_scale),
                                                           i_scores               => table_varchar(l_score_value),
                                                           i_id_scales_formulas   => table_number(l_id_score_formula),
                                                           o_id_epis_scales_score => o_id_epis_scales_score,
                                                           o_error                => o_error);
        
        ELSE
            RAISE my_exception;
        END IF;
    
        RETURN l_bool;
    
    EXCEPTION
        WHEN my_exception THEN
            RETURN FALSE;
    END get_all_score;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_api_touch_option;
/
