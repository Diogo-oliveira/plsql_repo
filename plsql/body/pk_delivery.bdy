/*-- Last Change Revision: $Rev: 2026939 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:29 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_delivery IS

    g_package_name VARCHAR2(32);
    FUNCTION error_handling
    (
        i_lang           IN language.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        o_error.err_desc := g_package_name || '.' || i_func_proc_name || ' / ' || i_error;
    
        pk_alert_exceptions.raise_error(error_code_in => SQLCODE,
                                        text_in       => i_error,
                                        name1_in      => 'OWNER',
                                        value1_in     => 'ALERT',
                                        name2_in      => 'PACKAGE',
                                        value2_in     => g_package_name,
                                        name3_in      => 'FUNCTION',
                                        value3_in     => i_func_proc_name);
    
        RETURN FALSE;
    END error_handling;

    FUNCTION error_handling_ext
    (
        i_lang           IN language.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlcode        IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        i_rollback       IN BOOLEAN,
        i_flg_action     IN VARCHAR2,
        i_action         IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error_in t_error_in := t_error_in();
        l_ret      BOOLEAN;
    
    BEGIN
    
        l_error_in.set_all(i_lang,
                           i_sqlcode,
                           i_sqlerror,
                           i_error,
                           'ALERT',
                           g_package_name,
                           i_func_proc_name,
                           i_action,
                           i_flg_action);
        l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
    
        IF i_rollback = TRUE
        THEN
            pk_utils.undo_changes;
        END IF;
        RETURN FALSE;
    END error_handling_ext;
    --    
    /********************************************************************************************
    * Converts the duration of the drug prescription into hours
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution IDs
    * @param i_duration              take duration
    * @param i_unit_measure          duration measure (minutes, days, hours)   
    * @param i_flg_take_type         flg_take_type: C - continuous
    * 
    * @return number of hours
    *
    * @author                        Jos?Silva
    * @version                       1.0    
    * @since                         06-05-2008
    * @dependents                    PK_DELIVERY
    ********************************************************************************************/
    FUNCTION get_delivery_duration_hours
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dt_begin      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_multiplier    IN NUMBER,
        i_flg_take_type IN drug_presc_det.flg_take_type%TYPE
    ) RETURN NUMBER IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_DELIVERY_DURATION_HOURS';
    
        l_min_unit_measure   CONSTANT unit_measure.id_unit_measure%TYPE := 10374;
        l_hours_unit_measure CONSTANT unit_measure.id_unit_measure%TYPE := 1041;
        l_day_unit_measure   CONSTANT unit_measure.id_unit_measure%TYPE := 1039;
        l_week_unit_measure  CONSTANT unit_measure.id_unit_measure%TYPE := 10375;
    
        l_error t_error_out;
    
    BEGIN
    
        IF i_flg_take_type = pk_alert_constant.g_presc_take_cont
        THEN
            RETURN round(pk_date_utils.get_timestamp_diff(i_dt_end, i_dt_begin) * i_multiplier);
        END IF;
    
        RETURN NULL;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_delivery_duration_hours;
    --
    /********************************************************************************************
    * Gets the number of registered fetus during the labor and delivery documentation
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_pat_pregnancy              pregnancy ID
    * @param o_fetus_number               number of registered fetus        
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Jos?Silva
    * @version                            1.0   
    * @since                              15-04-2008
    **********************************************************************************************/

    FUNCTION get_fetus_number
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_fetus_number  OUT epis_doc_delivery.fetus_number%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_fetus_number NUMBER;
    
    BEGIN
    
        g_error        := 'GET FETUS NUMBER';
        l_fetus_number := nvl(pk_pregnancy_api.get_fetus_number(i_lang, i_prof, i_pat_pregnancy), 1);
    
        IF l_fetus_number IS NULL
        THEN
        
            g_error := 'GET FETUS NUMBER 2';
            SELECT fetus_number
              INTO o_fetus_number
              FROM epis_doc_delivery edd
             WHERE edd.id_pat_pregnancy = i_pat_pregnancy
               AND edd.dt_register_tstz = (SELECT MAX(edd2.dt_register_tstz)
                                             FROM epis_doc_delivery edd2, epis_documentation ed
                                            WHERE edd2.id_pat_pregnancy = i_pat_pregnancy
                                              AND ed.id_epis_documentation = edd2.id_epis_documentation
                                              AND ed.flg_status = 'A'
                                              AND edd2.fetus_number IS NOT NULL);
        ELSE
            o_fetus_number := l_fetus_number;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_fetus_number := 1;
            RETURN TRUE;
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_FETUS_NUMBER', g_error, SQLERRM, o_error);
    END get_fetus_number;

    /********************************************************************************************
    * Gets the number of registered fetus during the labor and delivery documentation
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_pat_pregnancy              pregnancy ID
    * @param i_type                       date type: S - birth start date, E - birth end date
    * @param i_child_number               Child number    
    * @param o_fetus_number               number of registered fetus        
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Jos?Silva
    * @version                            1.0   
    * @since                              15-04-2008
    **********************************************************************************************/

    FUNCTION get_dt_birth
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_type          IN VARCHAR2,
        i_child_number  IN epis_doc_delivery.child_number%TYPE,
        o_dt_birth      OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET DATE BIRTH';
        SELECT edoc.dt_delivery_tstz
          INTO o_dt_birth
          FROM epis_documentation ed, epis_doc_delivery edoc
         WHERE edoc.id_pat_pregnancy = i_pat_pregnancy
           AND edoc.dt_register_tstz = (SELECT MAX(edd2.dt_register_tstz)
                                          FROM epis_doc_delivery edd2, epis_documentation ed2
                                         WHERE edd2.id_pat_pregnancy = i_pat_pregnancy
                                           AND ed2.id_epis_documentation = edd2.id_epis_documentation
                                           AND ed2.flg_status = 'A'
                                           AND ((edd2.child_number IS NULL AND i_type = g_type_dt_birth_s) OR
                                               (edd2.child_number = i_child_number AND i_type = g_type_dt_birth_e))
                                           AND edd2.dt_delivery_tstz IS NOT NULL)
           AND edoc.id_epis_documentation = ed.id_epis_documentation
           AND ed.flg_status = 'A'
           AND ((edoc.child_number IS NULL AND i_type = g_type_dt_birth_s) OR
               (edoc.child_number = i_child_number AND i_type = g_type_dt_birth_e))
           AND edoc.dt_delivery_tstz IS NOT NULL;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_dt_birth := NULL;
            RETURN TRUE;
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_DT_BIRTH', g_error, SQLERRM, o_error);
    END get_dt_birth;

    FUNCTION get_pat_dt_birth
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_type          IN VARCHAR2,
        i_child_number  IN epis_doc_delivery.child_number%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE AS
        l_dt_birth_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_error         t_error_out;
    BEGIN
        IF NOT get_dt_birth(i_lang, i_prof, i_pat_pregnancy, i_type, i_child_number, l_dt_birth_tstz, l_error)
        THEN
            RETURN NULL;
        END IF;
        RETURN l_dt_birth_tstz;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_dt_birth;
    /********************************************************************************************
    * Gets the registered value with the struture used in the partogram grid/graph
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_patient                    patient ID
    * @param i_pat_pregnancy              pregnancy ID
    *                    
    * @return                             value string
    *
    * @author                             Jos?Silva
    * @version                            2.6.0.5  
    * @since                              17-03-2011
    **********************************************************************************************/
    FUNCTION get_reg_value
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_pat_pregnancy        IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_vital_sign           IN vital_sign.id_vital_sign%TYPE,
        i_vs_parent            IN vital_sign_relation.id_vital_sign_parent%TYPE,
        i_value                IN vital_sign_read.value%TYPE,
        i_code_abbreviation    IN vital_sign_desc.code_abbreviation%TYPE,
        i_code_vital_sign_desc IN vital_sign_desc.code_vital_sign_desc%TYPE,
        i_icon                 IN vital_sign_desc.icon%TYPE,
        i_value_desc           IN vital_sign_desc.value%TYPE,
        i_grid_type            IN VARCHAR2,
        i_dt_vital_sign_read   IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_fetus_number         IN vital_sign_pregnancy.fetus_number%TYPE
    ) RETURN VARCHAR2 IS
    
        l_ret  VARCHAR2(1000 CHAR);
        l_icon vital_sign_desc.icon%TYPE;
    
        l_error   t_error_out;
        l_err_ret BOOLEAN;
    
    BEGIN
    
        g_error := 'GET VS VALUE';
        IF nvl(i_grid_type, g_type_table) = g_type_table
           AND i_vs_parent IS NOT NULL
        THEN
            SELECT vs2.value || '/' || i_value
              INTO l_ret
              FROM vital_sign_read vs2, vital_sign_relation vsr2, vital_sign_pregnancy vsp
             WHERE vs2.id_patient = i_patient
               AND vsr2.id_vital_sign_parent = i_vs_parent
               AND vs2.dt_vital_sign_read_tstz = i_dt_vital_sign_read
               AND vsr2.relation_domain = g_vs_rel_conc
               AND vs2.id_vital_sign = vsr2.id_vital_sign_detail
               AND vsp.id_pat_pregnancy = i_pat_pregnancy
               AND vsp.id_vital_sign_read = vs2.id_vital_sign_read
               AND vsp.fetus_number = i_fetus_number
               AND vsr2.rank = (SELECT MIN(rank)
                                  FROM vital_sign_relation
                                 WHERE id_vital_sign_parent = vsr2.id_vital_sign_parent
                                   AND relation_domain = g_vs_rel_conc);
        
            l_ret := l_ret || '|X|';
        
        ELSE
            IF i_vs_parent IS NULL
            THEN
                IF i_value IS NULL
                THEN
                    l_ret := nvl(pk_translation.get_translation(i_lang, i_code_abbreviation),
                                 pk_vital_sign.get_vs_alias(i_lang, i_patient, i_code_vital_sign_desc));
                
                ELSIF i_value IN (0, -1, 1)
                      OR i_value NOT BETWEEN - 1 AND 1
                THEN
                    l_ret := i_value;
                ELSE
                    l_ret := '0' || to_char(i_value);
                END IF;
            
                IF i_icon IS NULL
                   AND i_grid_type IS NOT NULL
                THEN
                    BEGIN
                        SELECT vd.icon
                          INTO l_icon
                          FROM vital_sign_desc vd, vital_sign_relation vr
                         WHERE vr.id_vital_sign_parent = i_vital_sign
                           AND vd.id_vital_sign = vr.id_vital_sign_detail
                           AND vr.relation_domain = g_vs_rel_graph
                           AND vd.id_vital_sign_desc =
                               (SELECT vsr2.id_vital_sign_desc
                                  FROM vital_sign_read vsr2, vital_sign_pregnancy vp2
                                 WHERE vsr2.id_vital_sign = vr.id_vital_sign_detail
                                   AND vsr2.id_vital_sign_read = vp2.id_vital_sign_read
                                   AND vsr2.flg_state = g_vs_read_active
                                   AND vp2.id_pat_pregnancy = i_pat_pregnancy
                                   AND vp2.fetus_number = i_fetus_number
                                   AND vsr2.dt_vital_sign_read_tstz = i_dt_vital_sign_read);
                    EXCEPTION
                        WHEN no_data_found THEN
                            NULL;
                    END;
                ELSE
                    l_icon := i_icon;
                END IF;
            
                l_ret := l_ret || '|' || nvl(l_icon, 'X') || '|' || nvl(i_value, i_value_desc);
            ELSE
                l_ret := i_value || '|' || 'X' || '|' || i_value;
            END IF;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            l_err_ret := error_handling(i_lang, 'GET_REG_VALUE', g_error, SQLERRM, l_error);
    END get_reg_value;

    /********************************************************************************************
    * Gets the registered value with the struture used in the partogram grid/graph
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids
    * @param i_hours                   list of hours that have delivery records
    * @param i_dt_delivery             delivery start date
    * @param i_dt_vital_sign_read      vital sign record date
    *                    
    * @return                             value string
    *
    * @author                             Jos?Silva
    * @version                            2.6.0.5  
    * @since                              17-03-2011
    **********************************************************************************************/
    FUNCTION get_hour_delivery
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_hours              IN table_number,
        i_dt_delivery        IN epis_doc_delivery.dt_delivery_tstz%TYPE,
        i_dt_vital_sign_read IN vital_sign_read.dt_vital_sign_read_tstz%TYPE
    ) RETURN NUMBER IS
    
        l_ret NUMBER;
    
        l_error   t_error_out;
        l_err_ret BOOLEAN;
    
    BEGIN
    
        g_error := 'GET HOUR DELIVERY';
        SELECT MIN(column_value)
          INTO l_ret
          FROM TABLE(i_hours)
         WHERE pk_date_utils.add_to_ltstz(i_dt_delivery, column_value, 'HOUR') >= i_dt_vital_sign_read;
    
        RETURN greatest(l_ret, 1);
    
    EXCEPTION
        WHEN OTHERS THEN
            l_err_ret := error_handling(i_lang, 'GET_HOUR_DELIVERY', g_error, SQLERRM, l_error);
    END get_hour_delivery;

    /********************************************************************************************
    * Gets the maximum time limit in the partogram graph
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_patient                    patient ID
    * @param i_episode                    episode ID
    * @param i_pat_pregnancy              pregnancy ID
    * @param i_fetus_number               fetus number
    * @param i_dt_birth                   delivery begin date
    * @param i_flg_type                   axis type 'G' - graph ; 'T' - table    
    * @param o_max_limit                  maximum time limit     
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Jos?Silva
    * @version                            1.0   
    * @since                              05-06-2009
    **********************************************************************************************/
    FUNCTION get_max_hour_graph
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_visit         IN visit.id_visit%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_fetus_number  IN NUMBER,
        i_dt_birth      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_type      IN VARCHAR2,
        o_max_limit     OUT NUMBER,
        o_num_hours     OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_vital_sign_read table_number := table_number();
        l_dt_drug            table_number := table_number();
        l_duration           table_number := table_number();
        l_hour_vs_read       NUMBER;
        l_hour_drug          NUMBER;
    
        l_flg_view vs_soft_inst.flg_view%TYPE;
    
        l_exception EXCEPTION;
    
    BEGIN
    
        IF i_flg_type = g_type_table
        THEN
            l_flg_view := g_flg_view;
        ELSE
            l_flg_view := g_view_delivery;
        END IF;
    
        g_error := 'GET MAX DT_VITAL_SIGN';
        IF i_fetus_number IS NOT NULL
        THEN
            SELECT DISTINCT ceil((trunc(SYSDATE) + (vsr.dt_vital_sign_read_tstz - i_dt_birth) - trunc(SYSDATE)) * 24) hour
              BULK COLLECT
              INTO l_dt_vital_sign_read
              FROM (SELECT dt_vital_sign_read_tstz, id_vital_sign, id_vital_sign_read
                      FROM vital_sign_read
                     WHERE id_patient = i_patient
                       AND dt_vital_sign_read_tstz >= i_dt_birth
                       AND flg_state = g_vs_read_active
                       AND id_vital_sign_desc IS NOT NULL
                    UNION
                    SELECT dt_vital_sign_read_tstz, id_vital_sign, id_vital_sign_read
                      FROM vital_sign_read
                     WHERE id_patient = i_patient
                       AND dt_vital_sign_read_tstz >= i_dt_birth
                       AND flg_state = g_vs_read_active
                       AND VALUE IS NOT NULL) vsr,
                   vital_sign vs,
                   vs_soft_inst vsi,
                   event e,
                   event_group eg,
                   (SELECT id_vital_sign_read
                      FROM vital_sign_pregnancy
                     WHERE id_pat_pregnancy = i_pat_pregnancy
                       AND fetus_number < i_fetus_number + 1) vsp
             WHERE (vs.id_vital_sign = vsr.id_vital_sign OR EXISTS
                    (SELECT 1
                       FROM vital_sign_relation vr
                      WHERE vr.id_vital_sign_parent = vs.id_vital_sign
                        AND vsr.id_vital_sign = vr.id_vital_sign_detail
                        AND vr.relation_domain = g_vs_rel_conc))
               AND vs.flg_available = g_vs_avail
               AND vsi.id_vital_sign = vs.id_vital_sign
               AND vsi.id_software IN (i_prof.software, 0)
               AND vsi.id_institution IN (i_prof.institution, 0)
               AND vsi.flg_view = l_flg_view
               AND e.flg_group = 'VS'
               AND eg.intern_name IN (g_intern_name_delivery, g_intern_name_fetus)
               AND eg.id_event_group = e.id_event_group
               AND (e.id_group = vsr.id_vital_sign OR EXISTS
                    (SELECT 1
                       FROM vital_sign_relation vr
                      WHERE vr.id_vital_sign_parent = e.id_group
                        AND vsr.id_vital_sign = vr.id_vital_sign_detail
                        AND vr.relation_domain = g_vs_rel_conc))
               AND vsp.id_vital_sign_read = vsr.id_vital_sign_read
             ORDER BY hour;
        END IF;
    
        g_error := 'GET MAX DT_DRUG';
        IF NOT pk_api_pfh_clindoc_in.get_delivery_max_drug(i_lang     => i_lang,
                                                           i_prof     => i_prof,
                                                           i_episode  => i_episode,
                                                           i_visit    => i_visit,
                                                           i_dt_birth => i_dt_birth,
                                                           o_dt_drug  => l_dt_drug,
                                                           o_duration => l_duration,
                                                           o_error    => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'GET NUM HOURS';
        IF l_dt_drug.last IS NOT NULL
        THEN
            l_hour_drug := l_dt_drug(l_dt_drug.last);
        
            FOR i IN 1 .. l_duration.count
            LOOP
                IF l_dt_drug(i) + l_duration(i) > l_hour_drug
                THEN
                    l_hour_drug := l_dt_drug(i) + l_duration(i);
                END IF;
            END LOOP;
        
            o_num_hours := l_dt_drug;
        ELSE
            l_hour_drug := 0;
        END IF;
    
        IF l_dt_vital_sign_read.last IS NOT NULL
        THEN
            l_hour_vs_read := l_dt_vital_sign_read(l_dt_vital_sign_read.last);
            o_num_hours    := l_dt_vital_sign_read;
        ELSE
            l_hour_vs_read := 0;
        END IF;
    
        o_max_limit := greatest(l_hour_vs_read, l_hour_drug);
    
        BEGIN
            IF o_num_hours IS NULL
            THEN
                o_num_hours := table_number();
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                o_num_hours := table_number();
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_MAX_HOUR_GRAPH', g_error, SQLERRM, o_error);
    END get_max_hour_graph;

    /********************************************************************************************
    * Converts a hexadecimal number to a decimal one and vice-versa
    *
    * @param i_number                     decimal number to convert
    * @param i_hexnum                     hexadecimal number to convert
    *                    
    * @return                             converted value
    *
    * @author                             Jos?Silva
    * @version                            1.0   
    * @since                              17-06-2009
    **********************************************************************************************/
    FUNCTION convert_hex2dec
    (
        i_number IN NUMBER,
        i_hexnum IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_digits            NUMBER;
        l_result            NUMBER := 0;
        l_current_digit     VARCHAR2(1);
        l_current_digit_dec NUMBER;
    
        l_hex VARCHAR2(64);
        l_n2  NUMBER := i_number;
    
    BEGIN
    
        IF i_hexnum IS NOT NULL
        THEN
            l_digits := length(i_hexnum);
            FOR i IN 1 .. l_digits
            LOOP
                l_current_digit := substr(i_hexnum, i, 1);
                IF l_current_digit IN ('A', 'B', 'C', 'D', 'E', 'F')
                THEN
                    l_current_digit_dec := ascii(l_current_digit) - ascii('A') + 10;
                ELSE
                    l_current_digit_dec := to_number(l_current_digit);
                END IF;
                l_result := (l_result * 16) + l_current_digit_dec;
            END LOOP;
        ELSIF i_number IS NOT NULL
        THEN
            LOOP
                SELECT rawtohex(chr(l_n2)) || l_hex
                  INTO l_hex
                  FROM dual;
            
                l_n2 := trunc(l_n2 / 256);
                EXIT WHEN l_n2 = 0;
            END LOOP;
        END IF;
    
        RETURN nvl(l_hex, to_char(l_result));
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END convert_hex2dec;

    /********************************************************************************************
    * Gets the hexadecimal color for a specific vital sign (depending on the fetus number)
    *
    * @param i_color                      original hexadecimal color
    * @param i_intern_name                vital sign type (patient or fetus)
    * @param i_fetus_number               current fetus number
    * @param i_total_fetus                total number of fetus
    * @param i_flg_view                   vital sign area (graph main view or graph backgrounf)
    *                    
    * @return                             hexadecimal color
    *
    * @author                             Jos?Silva
    * @version                            1.0   
    * @since                              17-06-2009
    **********************************************************************************************/
    FUNCTION get_graph_color
    (
        i_color        IN vs_soft_inst.color_grafh%TYPE,
        i_intern_name  IN time_event_group.intern_name%TYPE,
        i_fetus_number IN NUMBER,
        i_total_fetus  IN NUMBER,
        i_flg_view     IN vs_soft_inst.flg_view%TYPE
    ) RETURN VARCHAR2 IS
    
        l_color   vs_soft_inst.color_grafh%TYPE := i_color;
        l_r_value VARCHAR2(2);
        l_b_value VARCHAR2(2);
        l_g_value VARCHAR2(2);
    
        l_sum         NUMBER;
        l_b_dec_value NUMBER;
        l_r_dec_value NUMBER;
    
    BEGIN
    
        l_r_value := substr(i_color, 3, 2);
        l_b_value := substr(i_color, 5, 2);
        l_g_value := substr(i_color, 7, 2);
    
        l_sum := 30 + (10 - i_total_fetus) * 5;
    
        IF i_fetus_number > 1
           AND i_intern_name = g_intern_name_fetus
        THEN
            IF i_flg_view = g_view_delivery
            THEN
                l_r_value := 'FF';
            
                IF i_fetus_number > 2
                THEN
                    l_b_dec_value := to_number(convert_hex2dec(NULL, l_b_value));
                    l_b_dec_value := least(l_b_dec_value + l_sum * (i_fetus_number - 2), 255);
                    l_b_value     := convert_hex2dec(l_b_dec_value, NULL);
                END IF;
            
            ELSIF i_flg_view = g_flg_view
            THEN
                l_r_value := '33';
                l_g_value := 'FF';
            
                IF i_fetus_number > 2
                THEN
                    l_b_dec_value := to_number(convert_hex2dec(NULL, l_b_value));
                    l_b_dec_value := least(l_b_dec_value + l_sum * (i_fetus_number - 2), 255);
                    l_b_value     := convert_hex2dec(l_b_dec_value, NULL);
                END IF;
            
            END IF;
        
            l_color := '0x' || l_r_value || l_b_value || l_g_value;
        
        END IF;
    
        RETURN l_color;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_color;
    END get_graph_color;

    /********************************************************************************************
    * Checks if there are created episodes for a specific child
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_pat_pregnancy              pregnancy ID
    * @param i_child_number               child number
    * @param i_epis_documentation         assessment made to a specific child
    * @param o_epis_documentation         the same meaning as the previous parameter. This is filled if the child already has an episode.
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Jos?Silva
    * @version                            1.0   
    * @since                              16-04-2008
    **********************************************************************************************/

    FUNCTION exists_child_episode
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_child_number       IN epis_doc_delivery.child_number%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_epis_documentation OUT epis_documentation.id_epis_documentation%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_epis_doc_child IS
            SELECT edoc.id_epis_documentation
              FROM epis_doc_delivery edoc, episode e
             WHERE edoc.id_pat_pregnancy = i_pat_pregnancy
               AND edoc.child_number = nvl(i_child_number, edoc.child_number)
               AND edoc.id_child_episode = e.id_episode
                  --AND edoc.id_epis_documentation = i_epis_documentation
                  -- remove the filter by _epis_documentation since the second edit will create a newborn
               AND e.flg_status <> g_epis_cancel
             ORDER BY edoc.dt_register_tstz DESC;
    
    BEGIN
    
        g_error := 'CHECK CHILD EPISODES';
        OPEN c_epis_doc_child;
        FETCH c_epis_doc_child
            INTO o_epis_documentation;
        CLOSE c_epis_doc_child;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'EXISTS_CHILD_EPISODE', g_error, SQLERRM, o_error);
    END exists_child_episode;

    FUNCTION get_child_episode
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_child_number  IN epis_doc_delivery.child_number%TYPE,
        o_child_episode OUT epis_doc_delivery.id_child_episode%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET CHILD EPISODE';
        BEGIN
            SELECT edoc.id_child_episode
              INTO o_child_episode
              FROM epis_doc_delivery edoc
              JOIN epis_documentation ed
                ON ed.id_epis_documentation = edoc.id_epis_documentation
               AND ed.flg_status <> pk_touch_option.g_canceled
              JOIN episode e
                ON e.id_episode = edoc.id_child_episode
             WHERE edoc.id_pat_pregnancy = i_pat_pregnancy
               AND edoc.child_number = nvl(i_child_number, edoc.child_number)
               AND e.flg_status <> g_epis_cancel;
        EXCEPTION
            WHEN no_data_found THEN
                o_child_episode := NULL;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_CHILD_EPISODE', g_error, SQLERRM, o_error);
    END;

    /********************************************************************************************
    * Returns the dynamic elements of the partogram documentation
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution ids
    * @param i_id_doc_area           documentation area
    * @param i_id_doc_template       associated template    
    *
    * @return o_dyn_elements         dynamic elements and their relations
    * @return o_init_values          initial values for the action producing elements
    * @return                        true or false on success or error
    *
    * @author                        Jos?Silva
    * @version                       1.0    
    * @since                         24-08-2007
    ********************************************************************************************/
    FUNCTION get_delivery_dynamic_doc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_doc_area        IN doc_area.id_doc_area%TYPE,
        i_id_doc_template    IN doc_template.id_doc_template%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_dyn_elements       OUT pk_types.cursor_type,
        o_init_values        OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN CURSOR o_init_values';
        OPEN o_init_values FOR
            SELECT DISTINCT de.id_doc_element,
                            edd.id_doc_element_crit,
                            pk_touch_option.get_formatted_value(i_lang,
                                                                i_prof,
                                                                de.flg_type,
                                                                edd.value,
                                                                edd.value_properties,
                                                                de.input_mask,
                                                                de.flg_optional_value,
                                                                de.flg_element_domain_type,
                                                                de.code_element_domain) VALUE,
                            NULL init_crit
              FROM epis_documentation ed
             INNER JOIN epis_documentation_det edd
                ON ed.id_epis_documentation = edd.id_epis_documentation
             INNER JOIN epis_doc_delivery edoc
                ON ed.id_epis_documentation = edoc.id_epis_documentation
             INNER JOIN documentation_rel dr
                ON edd.id_doc_element_crit = dr.id_doc_element_crit
             INNER JOIN documentation d
                ON dr.id_documentation_action = d.id_documentation
             INNER JOIN doc_element_crit DEC
                ON dr.id_doc_element_crit = dec.id_doc_element_crit
             INNER JOIN doc_element de
                ON dec.id_doc_element = de.id_doc_element
             INNER JOIN doc_template_area_doc dtad
                ON dtad.id_documentation = d.id_documentation
             WHERE ed.flg_status = 'A'
               AND edoc.id_pat_pregnancy = i_pat_pregnancy
               AND ((edoc.dt_register_tstz =
                   (SELECT MAX(edoc2.dt_register_tstz)
                        FROM epis_doc_delivery edoc2, epis_documentation ed2, epis_documentation_det edd2
                       WHERE edoc2.id_epis_documentation = ed2.id_epis_documentation
                         AND edd2.id_epis_documentation = ed2.id_epis_documentation
                         AND edd2.id_doc_element_crit = edd.id_doc_element_crit
                         AND ed2.flg_status = 'A'
                         AND edoc2.id_pat_pregnancy = i_pat_pregnancy)) AND i_epis_documentation IS NULL OR
                   edoc.id_epis_documentation = i_epis_documentation)
               AND dr.flg_action IN ('S', 'H')
               AND dr.flg_available = 'Y'
               AND dtad.id_doc_template = i_id_doc_template
               AND dtad.id_doc_area = i_id_doc_area
            
            UNION
            
            SELECT DISTINCT de.id_doc_element,
                            dec.id_doc_element_crit,
                            nvl((SELECT to_char(nvl(p.n_children, 1))
                                  FROM pat_pregnancy p
                                 WHERE p.id_pat_pregnancy = i_pat_pregnancy),
                                '1') VALUE,
                            NULL init_crit
              FROM documentation_rel dr
             INNER JOIN doc_element_crit DEC
                ON dr.id_doc_element_crit = dec.id_doc_element_crit
             INNER JOIN doc_element de
                ON dec.id_doc_element = de.id_doc_element
             INNER JOIN documentation d
                ON dr.id_documentation_action = d.id_documentation
             INNER JOIN doc_template_area_doc dtad
                ON d.id_documentation = dtad.id_documentation
             WHERE dr.flg_action IN ('S', 'H')
               AND dr.flg_available = 'Y'
               AND dtad.id_doc_template = i_id_doc_template
               AND dtad.id_doc_area = i_id_doc_area
               AND de.flg_type <> 'S'
               AND de.id_doc_element NOT IN (SELECT edd2.id_doc_element
                                               FROM epis_documentation ed2
                                              INNER JOIN epis_documentation_det edd2
                                                 ON ed2.id_epis_documentation = edd2.id_epis_documentation
                                              INNER JOIN epis_doc_delivery edoc2
                                                 ON edoc2.id_epis_documentation = ed2.id_epis_documentation
                                              WHERE edoc2.id_pat_pregnancy = i_pat_pregnancy
                                                AND ed2.flg_status = 'A');
    
        g_error := 'OPEN CURSOR O_DYN_ELEMENTS';
        OPEN o_dyn_elements FOR
            SELECT de.id_doc_element,
                   dec.id_doc_element_crit,
                   dc.flg_criteria,
                   dr.id_documentation,
                   dr.id_documentation_action,
                   dr.value_action,
                   dr.flg_action
              FROM documentation_rel dr
             INNER JOIN documentation d
                ON dr.id_documentation_action = d.id_documentation
             INNER JOIN doc_element_crit DEC
                ON dr.id_doc_element_crit = dec.id_doc_element_crit
             INNER JOIN doc_element de
                ON dec.id_doc_element = de.id_doc_element
             INNER JOIN doc_criteria dc
                ON dc.id_doc_criteria = dec.id_doc_criteria
             INNER JOIN doc_template_area_doc dtad
                ON dtad.id_documentation = d.id_documentation
             WHERE dtad.id_doc_area = i_id_doc_area
               AND dtad.id_doc_template = i_id_doc_template
               AND dr.flg_action IN ('S', 'H')
               AND dr.flg_available = 'Y'
             ORDER BY de.id_doc_element, dr.id_documentation_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_dyn_elements);
            pk_types.open_my_cursor(o_init_values);
            RETURN error_handling_ext(i_lang,
                                      'GET_DELIVERY_DYNAMIC_DOC',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      NULL,
                                      o_error);
    END get_delivery_dynamic_doc;

    /********************************************************************************************
    * Gets the episode documentation related to woman health delivery for report purposes
    *
    * @param i_lang                  language id
    * @param i_prof_id               professional id
    * @param i_prof_inst             institution id
    * @param i_prof_sw               software id
    * @param i_episode               episode ID   
    * @param i_pat_pregancy          patient pregnancy id
    * @param i_doc_area              documentation area ID    
    *
    * @return o_doc_area_register    episode documentation IDs related to the i_pat_pregnancy ID
    * @return o_doc_area_val         episode documentation values related to the i_pat_pregnancy ID 
    * @return                        true or false on success or error
    *
    * @author                        Fábio Oliveira
    * @version                       1.0    
    * @since                         12-08-2008
    ********************************************************************************************/
    FUNCTION get_delivery_epis_doc_rep
    (
        i_lang              IN language.id_language%TYPE,
        i_prof_id           IN professional.id_professional%TYPE,
        i_prof_inst         IN institution.id_institution%TYPE,
        i_prof_sw           IN software.id_software%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_pat_pregnancy     IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN get_delivery_epis_doc(i_lang,
                                     profissional(i_prof_id, i_prof_inst, i_prof_sw),
                                     i_episode,
                                     i_pat_pregnancy,
                                     i_doc_area,
                                     o_doc_area_register,
                                     o_doc_area_val,
                                     o_error);
    END;

    /********************************************************************************************
    * Gets the episode documentation related to woman health delivery
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution ids
    * @param i_episode               episode ID   
    * @param i_pat_pregancy          patient pregnancy id
    * @param i_doc_area              documentation area ID    
    *
    * @return o_doc_area_register    episode documentation IDs related to the i_pat_pregnancy ID
    * @return o_doc_area_val         episode documentation values related to the i_pat_pregnancy ID 
    * @return                        true or false on success or error
    *
    * @author                        Jos?Silva
    * @version                       1.0    
    * @since                         27-08-2007
    ********************************************************************************************/
    FUNCTION get_delivery_epis_doc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_pat_pregnancy     IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_child_number epis_doc_delivery.child_number%TYPE;
        l_desc_child   sys_message.desc_message%TYPE;
    
        l_doc_area_register  pk_types.cursor_type;
        l_doc_area_val       pk_types.cursor_type;
        l_template_layouts   pk_types.cursor_type;
        l_doc_area_component pk_types.cursor_type;
    
        l_register pk_touch_option.t_rec_doc_area_register;
        l_val      pk_touch_option.t_rec_doc_area_val;
    
        l_exception EXCEPTION;
        l_error     t_error_out;
    
        CURSOR c_epis_visit IS
            SELECT e1.id_episode
              FROM episode e1, episode e2, visit v1, visit v2
             WHERE e2.id_episode = i_episode
               AND v1.id_visit = e1.id_visit
               AND v2.id_visit = e2.id_visit
               AND v1.id_patient = v2.id_patient
               AND EXISTS (SELECT 0
                      FROM epis_documentation ed
                     WHERE ed.id_episode = e1.id_episode
                       AND ed.id_doc_area = i_doc_area);
    
    BEGIN
    
        DELETE tmp_epis_doc_delivery;
        l_desc_child := pk_message.get_message(i_lang, 'WOMAN_HEALTH_T084');
    
        g_error := 'GET SAME VISIT EPISODES';
        FOR r_epis_visit IN c_epis_visit
        LOOP
        
            g_error := 'GET EPIS DOCUMENTATION';
            IF NOT pk_summary_page.get_summ_page_doc_area_value(i_lang,
                                                                i_prof,
                                                                r_epis_visit.id_episode,
                                                                i_doc_area,
                                                                l_doc_area_register,
                                                                l_doc_area_val,
                                                                l_template_layouts,
                                                                l_doc_area_component,
                                                                l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            LOOP
            
                g_error := 'FETCH l_doc_area_register';
                FETCH l_doc_area_register
                    INTO l_register;
            
                EXIT WHEN l_doc_area_register%NOTFOUND;
            
                g_error := 'INSERT l_register';
                INSERT INTO tmp_epis_doc_delivery
                    (order_by_default,
                     order_default,
                     id_epis_documentation,
                     PARENT,
                     id_doc_template,
                     dt_creation,
                     dt_register,
                     id_professional,
                     nick_name,
                     desc_speciality,
                     id_doc_area,
                     flg_status,
                     desc_status,
                     notes,
                     dt_last_update,
                     flg_type_register)
                VALUES
                    (l_register.order_by_default,
                     l_register.order_default,
                     l_register.id_epis_documentation,
                     l_register.parent,
                     l_register.id_doc_template,
                     l_register.dt_creation,
                     l_register.dt_register,
                     l_register.id_professional,
                     l_register.nick_name,
                     l_register.desc_speciality,
                     l_register.id_doc_area,
                     l_register.flg_status,
                     l_register.desc_status,
                     pk_string_utils.clob_to_sqlvarchar2(l_register.notes),
                     l_register.dt_last_update,
                     l_register.flg_type_register);
            
                BEGIN
                    SELECT e.child_number
                      INTO l_child_number
                      FROM epis_doc_delivery e
                     WHERE e.id_epis_documentation = l_register.id_epis_documentation;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_child_number := NULL;
                END;
            
                IF l_child_number IS NOT NULL
                THEN
                    g_error := 'INSERT l_val 1';
                    INSERT INTO tmp_epis_doc_delivery
                        (id_epis_documentation,
                         PARENT,
                         id_documentation,
                         id_doc_component,
                         id_doc_element_crit,
                         dt_reg,
                         desc_doc_component,
                         desc_element,
                         desc_element_view,
                         VALUE,
                         id_doc_area,
                         rank_component,
                         rank_element,
                         desc_doc_elem_qual_close)
                    VALUES
                        (l_register.id_epis_documentation,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         l_register.dt_register,
                         l_desc_child || ' ' || l_child_number,
                         NULL,
                         NULL,
                         NULL,
                         l_register.id_doc_area,
                         0,
                         NULL,
                         NULL);
                END IF;
            
            END LOOP;
        
            LOOP
                g_error := 'FETCH l_doc_area_val';
                FETCH l_doc_area_val
                    INTO l_val;
            
                EXIT WHEN l_doc_area_val%NOTFOUND;
            
                g_error := 'INSERT l_val';
                INSERT INTO tmp_epis_doc_delivery
                    (id_epis_documentation,
                     PARENT,
                     id_documentation,
                     id_doc_component,
                     id_doc_element_crit,
                     dt_reg,
                     desc_doc_component,
                     desc_element,
                     desc_element_view,
                     VALUE,
                     id_doc_area,
                     rank_component,
                     rank_element,
                     desc_doc_elem_qual_close)
                VALUES
                    (l_val.id_epis_documentation,
                     l_val.parent,
                     l_val.id_documentation,
                     l_val.id_doc_component,
                     l_val.id_doc_element_crit,
                     l_val.dt_reg,
                     l_val.desc_doc_component,
                     l_val.desc_element,
                     l_val.desc_element_view,
                     l_val.value,
                     l_val.id_doc_area,
                     l_val.rank_component,
                     l_val.rank_element,
                     l_val.desc_qualification);
            END LOOP;
        END LOOP;
    
        g_error := 'OPEN CURSOR o_doc_area_register';
        OPEN o_doc_area_register FOR
            SELECT tmp.id_epis_documentation,
                   tmp.parent,
                   tmp.id_doc_template,
                   tmp.dt_creation,
                   tmp.dt_register,
                   tmp.id_professional,
                   tmp.nick_name,
                   tmp.desc_speciality,
                   tmp.id_doc_area,
                   tmp.flg_status,
                   tmp.desc_status,
                   tmp.notes,
                   tmp.dt_last_update,
                   tmp.flg_type_register,
                   edd.child_number,
                   pk_touch_option.g_flg_tab_origin_epis_doc flg_table_origin, -- Record has its origin in the epis_documentation table
                   tmp.nick_name || ' (' || tmp.desc_speciality || '); ' || dt_register signature
              FROM tmp_epis_doc_delivery tmp, epis_doc_delivery edd
             WHERE edd.id_pat_pregnancy = i_pat_pregnancy
               AND edd.id_epis_documentation = tmp.id_epis_documentation
               AND tmp.id_professional IS NOT NULL;
    
        g_error := 'OPEN CURSOR o_doc_area_val';
        OPEN o_doc_area_val FOR
            SELECT tmp.id_epis_documentation,
                   tmp.parent,
                   tmp.id_documentation,
                   tmp.id_doc_component,
                   tmp.id_doc_element_crit,
                   tmp.dt_reg,
                   tmp.desc_doc_component,
                   tmp.desc_element,
                   tmp.desc_element_view,
                   tmp.value,
                   tmp.id_doc_area,
                   tmp.rank_component,
                   tmp.rank_element,
                   tmp.desc_doc_elem_qual_close desc_qualification
              FROM tmp_epis_doc_delivery tmp, epis_doc_delivery edd
             WHERE edd.id_pat_pregnancy = i_pat_pregnancy
               AND edd.id_epis_documentation = tmp.id_epis_documentation
               AND tmp.id_professional IS NULL
             ORDER BY tmp.id_epis_documentation, tmp.rank_component, tmp.rank_element;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            RETURN error_handling_ext(i_lang,
                                      'GET_DELIVERY_EPIS_DOC',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      NULL,
                                      o_error);
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            RETURN error_handling_ext(i_lang,
                                      'GET_DELIVERY_EPIS_DOC',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      NULL,
                                      o_error);
    END get_delivery_epis_doc;

    /********************************************************************************************
    * Sets the episode documentation related to woman health delivery
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution ids
    * @param i_pat_pregancy          patient pregnancy id
    * @param i_doc_element_val       doc_element IDs containing external info related to i_values
    * @param i_values                saved doc_element values
    * @param i_doc_element_ext       doc_element IDs containing external info related to i_doc_element_crit
    * @param i_doc_element_crit      saved doc_element crit
    * @param i_epis_documentation    epis documentation ID to save with given pat_pregnancy ID
    * @param i_child_number          child number associated to saved documentation
    *
    * @return                        true or false on success or error
    *
    * @author                        Jos?Silva
    * @version                       1.0    
    * @since                         27-08-2007
    *
    * @author                        Jos?Silva
    * @version                       2.0    
    * @since                         15-04-2008   
    ********************************************************************************************/
    FUNCTION set_delivery_epis_doc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_doc_template       IN doc_template.id_doc_template%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_doc_element_val    IN table_number,
        i_values             IN table_number,
        i_doc_element_ext    IN table_number,
        i_doc_element_crit   IN table_number,
        i_value              IN table_varchar,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_child_number       IN epis_doc_delivery.child_number%TYPE,
        o_child_status       OUT epis_doc_delivery.flg_child_status%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_doc_delivery  NUMBER;
        l_epis_documentation epis_documentation.id_epis_documentation%TYPE;
        l_id_doc_element     doc_element.id_doc_element%TYPE;
        l_fetus_number       epis_doc_delivery.fetus_number%TYPE;
        l_apgar              NUMBER;
        l_error_cancel       sys_message.desc_message%TYPE;
    
        l_found          BOOLEAN;
        l_error_epis_doc EXCEPTION;
        l_error_dt_birth EXCEPTION;
        l_error_dt_deliv EXCEPTION;
        l_msg_dt_birth   sys_message.desc_message%TYPE;
        l_msg_dt_deliv   sys_message.desc_message%TYPE;
    
        l_exception EXCEPTION;
        l_error     t_error_out;
    
        l_type_edit   CONSTANT VARCHAR2(1) := 'E';
        l_type_edit_h CONSTANT VARCHAR2(1) := 'H';
        l_type_set_pregn VARCHAR2(1) := l_type_edit_h;
    
        -- pregnancy summary page info
        l_name_child_alive  CONSTANT documentation_ext.internal_name%TYPE := 'CHILD_STATUS_ALIVE';
        l_name_child_dead   CONSTANT documentation_ext.internal_name%TYPE := 'CHILD_STATUS_DEAD';
        l_name_child_ignora CONSTANT documentation_ext.internal_name%TYPE := 'CHILD_STATUS_SE_IGNORA';
        l_name_fetus_weigh  CONSTANT documentation_ext.internal_name%TYPE := 'FETUS_WEIGHT';
        l_name_gender_m     CONSTANT documentation_ext.internal_name%TYPE := 'GENDER_MALE';
        l_name_gender_f     CONSTANT documentation_ext.internal_name%TYPE := 'GENDER_FEMALE';
        l_name_gender_i     CONSTANT documentation_ext.internal_name%TYPE := 'GENDER_I';
        --
        l_birth_cp CONSTANT documentation_ext.internal_name%TYPE := 'BIRTH_TYPE_CP';
        l_birth_cs CONSTANT documentation_ext.internal_name%TYPE := 'BIRTH_TYPE_CS';
        l_birth_cf CONSTANT documentation_ext.internal_name%TYPE := 'BIRTH_TYPE_CF';
        l_birth_df CONSTANT documentation_ext.internal_name%TYPE := 'BIRTH_TYPE_DF';
        l_birth_dv CONSTANT documentation_ext.internal_name%TYPE := 'BIRTH_TYPE_DV';
        l_birth_dc CONSTANT documentation_ext.internal_name%TYPE := 'BIRTH_TYPE_DC';
        l_birth_dt CONSTANT documentation_ext.internal_name%TYPE := 'BIRTH_TYPE_DT';
        l_birth_de CONSTANT documentation_ext.internal_name%TYPE := 'BIRTH_TYPE_DE';
        l_birth_dp CONSTANT documentation_ext.internal_name%TYPE := 'BIRTH_TYPE_DP';
        l_birth_o  CONSTANT documentation_ext.internal_name%TYPE := 'BIRTH_TYPE_O';
        l_birth_n  CONSTANT documentation_ext.internal_name%TYPE := 'BIRTH_TYPE_N';
        l_birth_c  CONSTANT documentation_ext.internal_name%TYPE := 'BIRTH_TYPE_C';
        --
        l_complications      CONSTANT documentation_ext.internal_name%TYPE := 'LABOR_COMPLICATIONS';
        l_post_complications CONSTANT documentation_ext.internal_name%TYPE := 'POST_LABOR_COMPLICATIONS';
        l_intervention       CONSTANT documentation_ext.internal_name%TYPE := 'DESC_INTERVENTION';
        l_flg_intervention   CONSTANT documentation_ext.internal_name%TYPE := 'FLG_DESC_INTERV';
        l_date_birth         CONSTANT documentation_ext.internal_name%TYPE := 'DATE_CHILD_BIRTH';
        --
        l_name_dt_delivery CONSTANT documentation_ext.internal_name%TYPE := 'DATE_DELIVERY_START';
    
        -- apgar values
        l_name_apgar_1  CONSTANT documentation_ext.internal_name%TYPE := 'APGAR_1';
        l_name_apgar_5  CONSTANT documentation_ext.internal_name%TYPE := 'APGAR_5';
        l_name_apgar_10 CONSTANT documentation_ext.internal_name%TYPE := 'APGAR_10';
    
        l_child_status       epis_doc_delivery.flg_child_status%TYPE;
        l_child_gender       pat_pregn_fetus.flg_gender%TYPE;
        l_t_child_weight     table_varchar;
        l_child_weight       pat_pregn_fetus.weight%TYPE;
        l_weight_um          pat_pregn_fetus.id_unit_measure%TYPE;
        l_str_dt_delivery    epis_documentation_det.value%TYPE;
        l_dt_delivery_tstz   TIMESTAMP WITH LOCAL TIME ZONE;
        l_birth_type         pat_pregn_fetus.flg_childbirth_type%TYPE;
        l_desc_complications pat_pregnancy.notes_complications%TYPE;
        l_desc_intervention  pat_pregnancy.desc_intervention%TYPE;
        l_flg_desc_interv    pat_pregnancy.flg_desc_intervention%TYPE;
        l_id_inst_interv     pat_pregnancy.id_inst_intervention%TYPE;
    
        l_dt_birth_tstz    TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_b_fetus_tstz  TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_last_menstr   TIMESTAMP WITH LOCAL TIME ZONE;
        l_crit_dt_birth    doc_element_crit.id_doc_element_crit%TYPE;
        l_crit_dt_delivery doc_element_crit.id_doc_element_crit%TYPE;
    
        l_str_dt_birth epis_documentation_det.value%TYPE;
    
        l_table_doc_ext table_varchar := table_varchar(l_name_child_alive,
                                                       l_name_child_dead,
                                                       l_name_child_ignora,
                                                       l_name_dt_delivery,
                                                       l_name_apgar_1,
                                                       l_name_apgar_5,
                                                       l_name_apgar_10,
                                                       l_name_fetus_weigh,
                                                       l_name_gender_m,
                                                       l_name_gender_f,
                                                       l_name_gender_i,
                                                       l_birth_cp,
                                                       l_birth_cs,
                                                       l_birth_cf,
                                                       l_birth_df,
                                                       l_birth_dv,
                                                       l_birth_dc,
                                                       l_birth_dt,
                                                       l_birth_de,
                                                       l_birth_dp,
                                                       l_birth_o,
                                                       l_birth_n,
                                                       l_birth_c,
                                                       l_complications,
                                                       l_post_complications,
                                                       l_flg_intervention,
                                                       l_intervention,
                                                       l_date_birth);
    
        l_fetus        NUMBER;
        l_number_fetus pat_pregn_fetus.fetus_number%TYPE;
        l_decimal_symb sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'DECIMAL_SYMBOL', i_prof => i_prof);
    
        CURSOR c_epis_doc_delivery IS
            SELECT 0
              FROM epis_doc_delivery edd
             WHERE edd.id_pat_pregnancy = i_pat_pregnancy
               AND edd.id_epis_documentation = i_epis_documentation;
    
        CURSOR c_doc_ext IS
            SELECT /*+ opt_estimate(table t rows=24)*/
             de.id_doc_element,
             pk_utils.str_token(de.value, 1, '|') VALUE,
             de.internal_name,
             de.flg_value,
             pk_utils.str_token(de.value, 2, '|') fetus_number
              FROM documentation_ext de
             INNER JOIN TABLE(l_table_doc_ext) t
                ON de.internal_name = t.column_value
             INNER JOIN doc_element del
                ON de.id_doc_element = del.id_doc_element
             INNER JOIN documentation d
                ON del.id_documentation = d.id_documentation
             INNER JOIN doc_template_area_doc dtad
                ON d.id_documentation = dtad.id_documentation
             WHERE dtad.id_doc_area = i_doc_area
               AND dtad.id_doc_template = i_doc_template
               AND (pk_utils.str_token(de.value, 2, '|') IS NULL OR pk_utils.str_token(de.value, 2, '|') <= l_fetus);
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error        := 'GET ERROR MESSAGES';
        l_msg_dt_birth := pk_message.get_message(i_lang, 'WOMAN_HEALTH_M008');
        l_msg_dt_deliv := pk_message.get_message(i_lang, 'WOMAN_HEALTH_M007');
    
        g_error := 'GET FETUS NUMBER ELEMENT';
        SELECT id_doc_element
          INTO l_id_doc_element
          FROM documentation_ext
         WHERE internal_name = 'FETUS_NUMBER';
    
        IF i_doc_element_val.count > 0
        THEN
            g_error := 'GET FETUS NUMBER';
            FOR i IN 1 .. i_doc_element_val.count
            LOOP
                IF i_doc_element_val(i) = l_id_doc_element
                THEN
                    l_fetus_number := i_values(i);
                END IF;
            END LOOP;
        END IF;
        IF l_fetus_number IS NOT NULL
        THEN
            l_fetus := l_fetus_number;
        ELSIF NOT get_fetus_number(i_lang, i_prof, i_pat_pregnancy, l_fetus, o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'CHECK EPIS_DOCUMENTATION IN EPIS_DOC_DELIVERY';
        OPEN c_epis_doc_delivery;
        FETCH c_epis_doc_delivery
            INTO l_epis_doc_delivery;
    
        l_found := c_epis_doc_delivery%NOTFOUND;
        CLOSE c_epis_doc_delivery;
    
        l_child_status := NULL;
    
        g_error := 'OPEN C_DOC_EXT_CHILD';
        FOR l_doc_ext IN c_doc_ext
        LOOP
            FOR i IN 1 .. i_doc_element_ext.count
            LOOP
                EXIT WHEN l_child_status IS NOT NULL AND l_str_dt_delivery IS NOT NULL AND l_apgar IS NOT NULL;
            
                g_error := 'CHECK CHILD STATUS';
                IF l_doc_ext.id_doc_element = i_doc_element_ext(i)
                   AND l_doc_ext.value = i_doc_element_crit(i)
                THEN
                    IF l_doc_ext.internal_name IN (l_name_child_alive, l_name_child_dead, l_name_child_ignora)
                    THEN
                        l_child_status := l_doc_ext.flg_value;
                    ELSIF l_doc_ext.internal_name IN (l_name_gender_m, l_name_gender_f, l_name_gender_i)
                    THEN
                        l_child_gender := l_doc_ext.flg_value;
                    ELSIF instr(l_doc_ext.internal_name, 'BIRTH_TYPE') > 0
                    THEN
                        l_number_fetus := l_doc_ext.fetus_number;
                        l_birth_type   := l_doc_ext.flg_value;
                    END IF;
                ELSIF l_doc_ext.id_doc_element = i_doc_element_ext(i)
                THEN
                    IF l_doc_ext.internal_name IN (l_name_apgar_1, l_name_apgar_5, l_name_apgar_10)
                    THEN
                        l_apgar := i_value(i);
                    ELSIF l_doc_ext.internal_name = l_name_fetus_weigh
                    THEN
                        l_t_child_weight := pk_utils.str_split_l(i_value(i), '|');
                    
                        l_child_weight := to_number(REPLACE(l_t_child_weight(1), '.', l_decimal_symb),
                                                    'FM999999999999999999999999D9999999999',
                                                    'NLS_NUMERIC_CHARACTERS= ''' || l_decimal_symb || ' ''');
                    
                        l_weight_um := l_t_child_weight(2);
                    ELSIF l_doc_ext.internal_name = l_intervention
                    THEN
                        l_desc_intervention := i_value(i);
                    ELSIF l_doc_ext.internal_name IN (l_complications, l_post_complications)
                    THEN
                        IF l_desc_complications IS NULL
                        THEN
                            l_desc_complications := i_value(i);
                        ELSE
                            l_desc_complications := l_desc_complications || chr(10) || i_value(i);
                        END IF;
                    ELSIF l_doc_ext.internal_name = l_date_birth
                    THEN
                        l_str_dt_birth  := i_value(i);
                        l_crit_dt_birth := i_doc_element_crit(i);
                    ELSIF l_doc_ext.internal_name = l_flg_intervention
                    THEN
                        IF i_value(i) IN ('D', 'O')
                        THEN
                            l_flg_desc_interv := i_value(i);
                        ELSE
                            l_id_inst_interv  := i_value(i);
                            l_flg_desc_interv := 'I';
                        END IF;
                    ELSIF i_value(i) IS NOT NULL
                    THEN
                        l_str_dt_delivery  := i_value(i);
                        l_crit_dt_delivery := i_doc_element_crit(i);
                    END IF;
                END IF;
            END LOOP;
        
            g_error := 'SET CHILD BIRTH TYPE';
            IF l_number_fetus IS NOT NULL
            THEN
                IF NOT pk_pregnancy_api.set_pat_pregn_delivery(i_lang,
                                                               i_prof,
                                                               i_pat_pregnancy,
                                                               i_doc_area,
                                                               l_number_fetus,
                                                               l_type_set_pregn,
                                                               NULL,
                                                               table_varchar(l_birth_type),
                                                               NULL,
                                                               NULL,
                                                               NULL,
                                                               NULL,
                                                               NULL,
                                                               NULL,
                                                               NULL,
                                                               NULL,
                                                               NULL,
                                                               l_error_cancel,
                                                               o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                l_type_set_pregn := l_type_edit;
            
            END IF;
        
        END LOOP;
    
        IF l_str_dt_birth IS NOT NULL
        THEN
            g_error           := 'BIRTH DATE';
            l_dt_b_fetus_tstz := pk_touch_option.get_value_tstz(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_doc_element_crit   => l_crit_dt_birth,
                                                                i_epis_documentation => i_epis_documentation);
            IF i_child_number = l_fetus
            THEN
                l_dt_birth_tstz := l_dt_b_fetus_tstz;
            END IF;
        
        ELSIF l_str_dt_delivery IS NOT NULL
        THEN
            g_error            := 'DELIVERY DATE';
            l_dt_delivery_tstz := pk_touch_option.get_value_tstz(i_lang               => i_lang,
                                                                 i_prof               => i_prof,
                                                                 i_doc_element_crit   => l_crit_dt_delivery,
                                                                 i_epis_documentation => i_epis_documentation);
        END IF;
    
        g_error := 'CHECK DATE INTEGRITY';
        SELECT pk_date_utils.get_string_tstz(i_lang,
                                             i_prof,
                                             (to_char(p.dt_init_pregnancy,
                                                      pk_sysconfig.get_config('DATE_HOUR_SEND_FORMAT', i_prof))),
                                             NULL)
          INTO l_dt_last_menstr
          FROM pat_pregnancy p
         WHERE p.id_pat_pregnancy = i_pat_pregnancy;
    
        IF l_dt_b_fetus_tstz > current_timestamp
           OR l_dt_b_fetus_tstz <= l_dt_last_menstr
        THEN
            RAISE l_error_dt_birth;
        ELSIF l_dt_delivery_tstz > current_timestamp
              OR l_dt_delivery_tstz <= l_dt_last_menstr
        THEN
            RAISE l_error_dt_deliv;
        END IF;
    
        g_error := 'CHECK CHILD STATUS';
        IF nvl(l_child_status, '0') != g_child_status_dead
           AND l_apgar > 0
        THEN
            l_child_status := g_child_status_alive;
        END IF;
    
        g_error := 'CHECK CHILD EPISODE INTEGRITY';
        IF NOT
            exists_child_episode(i_lang, i_prof, i_pat_pregnancy, i_child_number, NULL, l_epis_documentation, l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF l_epis_documentation IS NOT NULL
           AND l_child_status = g_child_status_dead
        THEN
            RAISE l_error_epis_doc;
        END IF;
    
        g_error := 'UPDATE PAT PREGNANCY';
        IF l_dt_birth_tstz IS NOT NULL
           OR l_desc_intervention IS NOT NULL
           OR l_flg_desc_interv IS NOT NULL
           OR l_id_inst_interv IS NOT NULL
           OR l_desc_complications IS NOT NULL
        THEN
            IF NOT pk_pregnancy_api.set_pat_pregn_delivery(i_lang,
                                                           i_prof,
                                                           i_pat_pregnancy,
                                                           i_doc_area,
                                                           NULL,
                                                           l_type_set_pregn,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           l_dt_birth_tstz,
                                                           l_desc_intervention,
                                                           l_flg_desc_interv,
                                                           l_id_inst_interv,
                                                           l_desc_complications,
                                                           NULL,
                                                           l_error_cancel,
                                                           o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            l_type_set_pregn := l_type_edit;
        
        END IF;
    
        IF l_found
        THEN
        
            g_error := 'INSERT INTO EPIS_DOC_DELIVERY';
            INSERT INTO epis_doc_delivery
                (id_pat_pregnancy,
                 id_epis_documentation,
                 fetus_number,
                 dt_register_tstz,
                 child_number,
                 flg_child_status,
                 dt_delivery_tstz)
            VALUES
                (i_pat_pregnancy,
                 i_epis_documentation,
                 l_fetus_number,
                 g_sysdate_tstz,
                 i_child_number,
                 l_child_status,
                 nvl(l_dt_delivery_tstz, l_dt_b_fetus_tstz));
        ELSE
            g_error := 'UPDATE EPIS_DOC_DELIVERY';
            UPDATE epis_doc_delivery edd
               SET edd.fetus_number     = l_fetus_number,
                   edd.flg_child_status = l_child_status,
                   edd.dt_delivery_tstz = nvl(l_dt_delivery_tstz, l_dt_b_fetus_tstz)
             WHERE edd.id_pat_pregnancy = i_pat_pregnancy
               AND edd.id_epis_documentation = i_epis_documentation;
        END IF;
    
        IF i_child_number IS NOT NULL
        THEN
            g_error := 'SET FETUS INFO';
            IF NOT pk_pregnancy_api.set_pat_pregn_delivery(i_lang,
                                                           i_prof,
                                                           i_pat_pregnancy,
                                                           i_doc_area,
                                                           i_child_number,
                                                           l_type_set_pregn,
                                                           table_varchar(l_child_gender),
                                                           NULL,
                                                           table_varchar(l_child_status),
                                                           table_number(l_child_weight),
                                                           table_varchar(l_weight_um),
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           l_error_cancel,
                                                           o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        END IF;
    
        o_child_status := l_child_status;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_error_epis_doc THEN
            o_child_status := g_child_status_err;
            RETURN TRUE;
        WHEN l_error_dt_birth THEN
            RETURN error_handling_ext(i_lang,
                                      'SET_DELIVERY_EPIS_DOC',
                                      '',
                                      'WOMAN_HEALTH_M008',
                                      l_msg_dt_birth,
                                      TRUE,
                                      'D',
                                      NULL,
                                      o_error);
        WHEN l_error_dt_deliv THEN
            RETURN error_handling_ext(i_lang,
                                      'SET_DELIVERY_EPIS_DOC',
                                      '',
                                      'WOMAN_HEALTH_M007',
                                      l_msg_dt_deliv,
                                      TRUE,
                                      'D',
                                      NULL,
                                      o_error);
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang,
                                      'SET_DELIVERY_EPIS_DOC',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      NULL,
                                      o_error);
    END set_delivery_epis_doc;

    /********************************************************************************************
    * Gets the sections presented in the delivery evaluation
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution ids
    * @param i_id_summary_page       summary page ID
    * @param i_id_pat_pregnancy      pregnancy ID       
    *
    * @return o_sections             evaluation sections 
    * @return o_value                the number of fetus documented in the assessment   
    * @return                        true or false on success or error
    *
    * @author                        Jos?Silva, Luís Gaspar
    * @version                       1.0    
    * @since                         29-08-2007
    ********************************************************************************************/
    FUNCTION get_delivery_sections
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_summary_page  IN summary_page.id_summary_page%TYPE,
        i_id_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_sections         OUT pk_types.cursor_type,
        o_value            OUT NUMBER,
        o_dt_format        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_internal_exception EXCEPTION;
        l_error              t_error_out;
        l_pat                NUMBER;
    
    BEGIN
    
        g_error := 'GET PATIENT ID';
        BEGIN
            SELECT id_patient
              INTO l_pat
              FROM pat_pregnancy
             WHERE id_pat_pregnancy = i_id_pat_pregnancy;
        EXCEPTION
            WHEN no_data_found THEN
                l_pat := NULL;
        END;
    
        IF l_pat IS NOT NULL
        THEN
            g_error := 'GET FETUS NUMBER';
            IF NOT get_fetus_number(i_lang, i_prof, i_id_pat_pregnancy, o_value, l_error)
            THEN
                RAISE l_internal_exception;
            END IF;
        
            g_error := 'CALL PK_SUMMARY_PAGE.get_summary_page_sections';
            IF NOT pk_summary_page.get_summary_page_sections(i_lang            => i_lang,
                                                             i_prof            => i_prof,
                                                             i_id_summary_page => i_id_summary_page,
                                                             i_pat             => l_pat,
                                                             o_sections        => o_sections,
                                                             o_error           => l_error)
            THEN
                RAISE l_internal_exception;
            END IF;
        
            g_error     := 'GET DATE FORMAT';
            o_dt_format := pk_sysconfig.get_config('DATE_HOUR_FORMAT_FLASH', i_prof);
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_exception THEN
            pk_types.open_my_cursor(o_sections);
            RETURN error_handling_ext(i_lang,
                                      'GET_DELIVERY_SECTIONS',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      NULL,
                                      o_error);
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_sections);
            RETURN error_handling_ext(i_lang,
                                      'GET_DELIVERY_SECTIONS',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      NULL,
                                      o_error);
    END get_delivery_sections;

    /********************************************************************************************
    * Gets the axis to fill the monitoring grid
    *
    * @param i_lang                  language id
    * @param i_patient               patient id
    * @param i_episode               episode id
    * @param i_prof                  professional, software and institution ids
    * @param i_pat_pregnancy         pregnancy id
    *
    * @return o_time                 time event axis
    * @return o_sign_v               available vital signs             
    * @return o_dt_ini               minimum vital sign limit
    * @return o_dt_end               maximum vital sign limit
    * @return                        true or false on success or error
    *
    * @author                        Jos?Silva
    * @version                       1.0    
    * @since                         31-08-2007
    ********************************************************************************************/

    FUNCTION get_delivery_axis
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_time          OUT pk_types.cursor_type,
        o_sign_v        OUT pk_types.cursor_type,
        o_dt_ini        OUT VARCHAR2,
        o_dt_end        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count           NUMBER;
        l_param_exception EXCEPTION;
        l_age             vital_sign_unit_measure.age_min%TYPE;
    
    BEGIN
    
        l_age := pk_patient.get_pat_age(i_lang, NULL, NULL, NULL, 'MONTHS', i_patient);
    
        g_error := 'COUNT VITAL SIGNS';
        SELECT COUNT(*)
          INTO l_count
          FROM (SELECT vs.id_vital_sign, um.id_unit_measure, eg.intern_name, COUNT(*) c_vs
                  FROM vital_sign vs, vs_soft_inst vsi, unit_measure um, event e, event_group eg
                 WHERE vs.flg_available = g_vs_avail
                   AND vsi.id_vital_sign = vs.id_vital_sign
                   AND vsi.id_software IN (i_prof.software, 0)
                   AND vsi.id_institution IN (i_prof.institution, 0)
                   AND vsi.flg_view IN (g_flg_view)
                   AND um.id_unit_measure(+) = vsi.id_unit_measure
                   AND e.flg_group = 'VS'
                   AND eg.intern_name IN (g_intern_name_delivery, g_intern_name_fetus)
                   AND eg.id_event_group = e.id_event_group
                   AND e.id_group = vs.id_vital_sign
                 GROUP BY vs.id_vital_sign, um.id_unit_measure, eg.intern_name
                HAVING COUNT(*) > 1);
    
        g_error := 'CHECK VS_PARAM';
        IF l_count > 0
        THEN
            g_error := 'CONFIGURATIONS ERROR';
            RAISE l_param_exception;
        END IF;
    
        g_error := 'CALL TO GET_VS_LIMIT_DATES';
        IF NOT pk_vital_sign.get_vs_date_limits(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_patient           => i_patient,
                                                i_episode           => i_episode,
                                                i_id_monitorization => NULL,
                                                o_dt_ini            => o_dt_ini,
                                                o_dt_end            => o_dt_end,
                                                o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN CURSOR O_TIME';
        OPEN o_time FOR
            SELECT /*+use_concat*/
             vsr.dt_vital_sign_read_tstz,
             pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) dt_vital_sign_read,
             substr(pk_date_utils.date_chr_space_tsz(i_lang,
                                                     vsr.dt_vital_sign_read_tstz,
                                                     i_prof.institution,
                                                     i_prof.software),
                    0,
                    6) short_dt_read,
             pk_date_utils.date_char_hour_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof.institution, i_prof.software) hour_read,
             pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                   vsr.dt_vital_sign_read_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) dt_read
              FROM vital_sign_read      vsr,
                   vital_sign           vs,
                   vs_soft_inst         vsi,
                   event                e,
                   event_group          eg,
                   vital_sign_pregnancy vsp
             WHERE (vs.id_vital_sign = vsr.id_vital_sign OR EXISTS
                    (SELECT 1
                       FROM vital_sign_relation vr
                      WHERE vr.id_vital_sign_parent = vs.id_vital_sign
                        AND vsr.id_vital_sign = vr.id_vital_sign_detail
                        AND vr.relation_domain = g_vs_rel_conc))
               AND vs.flg_available = g_vs_avail
               AND vsi.id_vital_sign = vs.id_vital_sign
               AND vsi.id_software IN (i_prof.software, 0)
               AND vsi.id_institution IN (i_prof.institution, 0)
               AND vsi.flg_view = g_flg_view
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND eg.intern_name IN (g_intern_name_delivery, g_intern_name_fetus)
               AND eg.id_event_group = e.id_event_group
               AND (e.id_group = vsr.id_vital_sign OR EXISTS
                    (SELECT 1
                       FROM vital_sign_relation vr
                      WHERE vr.id_vital_sign_parent = e.id_group
                        AND vsr.id_vital_sign = vr.id_vital_sign_detail
                        AND vr.relation_domain = g_vs_rel_conc))
               AND vsp.id_vital_sign_read = vsr.id_vital_sign_read
               AND vsp.id_pat_pregnancy = i_pat_pregnancy
             GROUP BY vsr.dt_vital_sign_read_tstz
             ORDER BY vsr.dt_vital_sign_read_tstz;
    
        g_error := 'OPEN CURSOR O_SIGN_V';
        OPEN o_sign_v FOR
            SELECT vs.id_vital_sign,
                   pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                   vsi.rank,
                   (SELECT pk_vital_sign_core.get_vsum_val_min(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_id_vital_sign   => vs.id_vital_sign,
                                                               i_id_unit_measure => vsi.id_unit_measure,
                                                               i_id_institution  => i_prof.institution,
                                                               i_id_software     => i_prof.software,
                                                               i_age             => l_age)
                      FROM dual) val_min,
                   (SELECT pk_vital_sign_core.get_vsum_val_max(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_id_vital_sign   => vs.id_vital_sign,
                                                               i_id_unit_measure => vsi.id_unit_measure,
                                                               i_id_institution  => i_prof.institution,
                                                               i_id_software     => i_prof.software,
                                                               i_age             => l_age)
                      FROM dual) val_max,
                   vsi.color_grafh,
                   vsi.color_text,
                   vsi.id_unit_measure,
                   pk_translation.get_translation(i_lang, 'UNIT_MEASURE.CODE_UNIT_MEASURE.' || vsi.id_unit_measure) desc_unit_measure,
                   e.flg_group,
                   vs.flg_fill_type,
                   decode(eg.intern_name, g_intern_name_delivery, 0, g_intern_name_fetus, 1) id_grid,
                   CAST(MULTISET (SELECT vr.id_vital_sign_detail
                           FROM vital_sign_relation vr
                          WHERE vr.id_vital_sign_parent = vs.id_vital_sign
                            AND vr.relation_domain = g_vs_rel_conc) AS table_number) vs_detail,
                   (SELECT DISTINCT vr.relation_domain
                      FROM vital_sign_relation vr
                     WHERE vr.id_vital_sign_parent = vs.id_vital_sign
                       AND vr.relation_domain = g_vs_rel_conc) relation_domain,
                   (SELECT pk_vital_sign_core.get_vsum_format_num(i_lang            => i_lang,
                                                                  i_prof            => i_prof,
                                                                  i_id_vital_sign   => vs.id_vital_sign,
                                                                  i_id_unit_measure => vsi.id_unit_measure,
                                                                  i_id_institution  => i_prof.institution,
                                                                  i_id_software     => i_prof.software,
                                                                  i_age             => l_age)
                      FROM dual) format_num
              FROM vital_sign vs, vs_soft_inst vsi, event e, event_group eg
             WHERE vs.flg_available = g_vs_avail
               AND vsi.id_vital_sign = vs.id_vital_sign
               AND vsi.id_software IN (i_prof.software, 0)
               AND vsi.id_institution IN (i_prof.institution, 0)
               AND vsi.flg_view = g_flg_view
               AND e.flg_group = 'VS'
               AND eg.intern_name IN (g_intern_name_delivery, g_intern_name_fetus)
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_vital_sign
             ORDER BY id_grid, vsi.rank, name_vs; --, vs.id_vital_sign;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_param_exception THEN
            pk_types.open_my_cursor(o_sign_v);
            pk_types.open_my_cursor(o_time);
            RETURN error_handling_ext(i_lang,
                                      'GET_DELIVERY_AXIS',
                                      g_error,
                                      SQLCODE,
                                      g_error,
                                      FALSE,
                                      'S',
                                      NULL,
                                      o_error);
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_sign_v);
            pk_types.open_my_cursor(o_time);
            RETURN error_handling_ext(i_lang,
                                      'GET_DELIVERY_AXIS',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      NULL,
                                      o_error);
    END get_delivery_axis;

    /********************************************************************************************
    * Gets the values to fill the monitoring grid
    *
    * @param i_lang                  language id
    * @param i_patient               patient id
    * @param i_prof                  professional, software and institution ids
    * @param i_pat_pregnancy         pregnancy id
    * @param i_fetus_number          the number of fetus documented in the assessment   
    *
    * @return o_val_vs               vital sign values             
    * @return                        true or false on success or error
    *
    * @author                        Jos?Silva
    * @version                       1.0    
    * @since                         31-08-2007
    ********************************************************************************************/

    FUNCTION get_delivery_time_event
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_fetus_number  IN NUMBER,
        o_val_vs        OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count NUMBER;
        l_sep   VARCHAR2(1);
    
        l_array_fetus table_varchar;
        l_init_count  NUMBER;
    
        l_current_fetus NUMBER;
    
        CURSOR c_time IS
            SELECT /*+use_concat*/
             vsr.dt_vital_sign_read_tstz dt_vital_sign_read
              FROM vital_sign_read      vsr,
                   vital_sign           vs,
                   vs_soft_inst         vsi,
                   event                e,
                   event_group          eg,
                   vital_sign_pregnancy vsp
             WHERE (vs.id_vital_sign = vsr.id_vital_sign OR EXISTS
                    (SELECT 1
                       FROM vital_sign_relation vr
                      WHERE vr.id_vital_sign_parent = vs.id_vital_sign
                        AND vsr.id_vital_sign = vr.id_vital_sign_detail
                        AND vr.relation_domain = g_vs_rel_conc))
               AND vs.flg_available = g_vs_avail
               AND vsi.id_vital_sign = vs.id_vital_sign
               AND vsi.id_software IN (i_prof.software, 0)
               AND vsi.id_institution IN (i_prof.institution, 0)
               AND vsi.flg_view = g_flg_view
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND eg.id_event_group = e.id_event_group
               AND (e.id_group = vsr.id_vital_sign OR EXISTS
                    (SELECT 1
                       FROM vital_sign_relation vr
                      WHERE vr.id_vital_sign_parent = e.id_group
                        AND vsr.id_vital_sign = vr.id_vital_sign_detail
                        AND vr.relation_domain = g_vs_rel_conc))
               AND vsp.id_pat_pregnancy = i_pat_pregnancy
               AND vsp.id_vital_sign_read = vsr.id_vital_sign_read
             GROUP BY vsr.dt_vital_sign_read_tstz
             ORDER BY vsr.dt_vital_sign_read_tstz;
    
        CURSOR c_vital IS
            SELECT vs.id_vital_sign,
                   pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                   vsi.rank,
                   decode(eg.intern_name, g_intern_name_delivery, 0, g_intern_name_fetus, 1) id_grid,
                   vr.relation_domain
              FROM vital_sign vs, vs_soft_inst vsi, event e, event_group eg, vital_sign_relation vr
             WHERE vs.flg_available = g_vs_avail
               AND vsi.id_vital_sign = vs.id_vital_sign
               AND vsi.id_software IN (i_prof.software, 0)
               AND vsi.id_institution IN (i_prof.institution, 0)
               AND vsi.flg_view = g_flg_view
               AND e.flg_group = 'VS'
               AND eg.intern_name IN (g_intern_name_delivery, g_intern_name_fetus)
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_vital_sign
               AND vr.id_vital_sign_parent(+) = vs.id_vital_sign
               AND vr.relation_domain(+) = g_vs_rel_conc
             GROUP BY vs.id_vital_sign, vs.code_vital_sign, vsi.rank, eg.intern_name, vr.relation_domain
             ORDER BY id_grid, vsi.rank, name_vs, vs.id_vital_sign;
    
        CURSOR c_values IS
            SELECT pk_delivery.get_reg_value(i_lang,
                                             i_prof,
                                             i_patient,
                                             i_pat_pregnancy,
                                             vsr.id_vital_sign,
                                             vsr3.id_vital_sign_parent,
                                             vsr.value,
                                             vdesc.code_abbreviation,
                                             vdesc.code_vital_sign_desc,
                                             vdesc.icon,
                                             vdesc.value,
                                             NULL,
                                             vsr.dt_vital_sign_read_tstz,
                                             vsp.fetus_number) VALUE,
                   vsr.id_vital_sign_read,
                   decode(vsr.dt_cancel_tstz, '', 'A', 'C') reg,
                   'S' flg_reg,
                   nvl(vsp.fetus_number, 0) fetus_number,
                   pk_translation.get_translation(i_lang, 'UNIT_MEASURE.CODE_UNIT_MEASURE.' || vsr.id_unit_measure) desc_unit_measure,
                   nvl(vsr3.id_vital_sign_parent, vsr.id_vital_sign) id_vital_sign,
                   nvl(pk_translation.get_translation(i_lang, vdesc.code_abbreviation),
                       pk_vital_sign.get_vs_alias(i_lang, i_patient, vdesc.code_vital_sign_desc)) name_vs,
                   pk_translation.get_translation(i_lang, vs.code_vital_sign) vs_desc,
                   vsr.dt_vital_sign_read_tstz,
                   decode(vsp.fetus_number, 0, 0, 1) id_grid
              FROM vital_sign_read      vsr,
                   vital_sign           vs,
                   vital_sign_desc      vdesc,
                   vital_sign_pregnancy vsp,
                   vital_sign_relation  vsr3,
                   vs_soft_inst         vsi
             WHERE vs.id_vital_sign = vsr.id_vital_sign
               AND vsr.id_vital_sign = vsr3.id_vital_sign_detail(+)
               AND vs.flg_available = g_vs_avail
               AND vsi.id_vital_sign = nvl(vsr3.id_vital_sign_parent, vsr.id_vital_sign)
               AND vsi.id_software IN (i_prof.software, 0)
               AND vsi.id_institution IN (i_prof.institution, 0)
               AND vsi.flg_view = g_flg_view
               AND vsr3.relation_domain(+) = g_vs_rel_conc
               AND vsr.id_vital_sign_desc = vdesc.id_vital_sign_desc(+) -- Jos?Brito 18/12/2008 ALERT-9992
               AND vsr.id_vital_sign = vdesc.id_vital_sign(+)
               AND vsr.id_patient = i_patient
               AND vsp.id_pat_pregnancy = i_pat_pregnancy
               AND vsp.id_vital_sign_read = vsr.id_vital_sign_read
               AND nvl(vsr3.rank, -1) = nvl((SELECT MAX(rank)
                                              FROM vital_sign_relation
                                             WHERE id_vital_sign_parent = vsr3.id_vital_sign_parent
                                               AND relation_domain = g_vs_rel_conc),
                                            -1)
             ORDER BY id_grid, vsi.rank, vs_desc, id_vital_sign, vsr.dt_vital_sign_read_tstz;
    
        TYPE dataset_values IS TABLE OF c_values%ROWTYPE INDEX BY PLS_INTEGER;
    
        l_time     table_timestamp_tstz := table_timestamp_tstz();
        l_values   dataset_values;
        l_curr_idx PLS_INTEGER := 1;
    
    BEGIN
    
        l_count := 0;
        l_sep   := ';';
    
        l_current_fetus := i_fetus_number;
    
        g_error := 'GET TIME VALUES';
        OPEN c_time;
        FETCH c_time BULK COLLECT
            INTO l_time;
        CLOSE c_time;
    
        g_error := 'GET VS VALUES';
        OPEN c_values;
        FETCH c_values BULK COLLECT
            INTO l_values;
        CLOSE c_values;
    
        g_error       := 'INICIALIZAÇÃO';
        o_val_vs      := table_varchar(); -- inicialização do vector
        l_array_fetus := table_varchar();
        FOR i IN 1 .. (l_current_fetus + 2)
        LOOP
            l_array_fetus.extend;
        END LOOP;
    
        g_error := 'GET CURSOR C_VITAL';
        FOR r_vital IN c_vital
        LOOP
        
            IF l_count > 0
            THEN
                FOR i IN 1 .. (l_current_fetus + 1)
                LOOP
                    IF l_array_fetus(i) IS NOT NULL
                    THEN
                        o_val_vs.extend;
                        o_val_vs(l_count) := l_array_fetus(i) || l_sep;
                        l_count := l_count + 1;
                    END IF;
                END LOOP;
            ELSE
                l_count := l_count + 1;
            END IF;
        
            IF r_vital.id_grid = 0
            THEN
                l_current_fetus := 0;
            ELSE
                l_current_fetus := i_fetus_number;
            END IF;
        
            l_array_fetus(1) := NULL;
        
            IF l_current_fetus = 0
            THEN
                l_init_count := 1;
                l_array_fetus(1) := 0 || l_sep || r_vital.id_vital_sign || l_sep;
            ELSE
                l_init_count := 2;
                FOR i IN 2 .. (l_current_fetus + 1)
                LOOP
                    l_array_fetus(i) := NULL;
                    l_array_fetus(i) := i - 1 || l_sep || r_vital.id_vital_sign || l_sep;
                END LOOP;
            END IF;
        
            g_error := 'GET CURSOR C_TIME';
            FOR i IN 1 .. l_time.count
            LOOP
            
                g_error := 'GET CURSOR C_VALUES' || r_vital.id_vital_sign;
                FOR j IN l_curr_idx .. l_values.count
                LOOP
                    IF l_time(i) = l_values(j).dt_vital_sign_read_tstz
                       AND l_values(j).fetus_number < (l_current_fetus + 1)
                       AND l_values(j).id_vital_sign = r_vital.id_vital_sign
                    THEN
                    
                        l_array_fetus(l_values(j).fetus_number + 1) := l_array_fetus(l_values(j).fetus_number + 1) || l_values(j).id_vital_sign_read || '|' || l_values(j).flg_reg || '|' || l_values(j).reg || '|' || l_values(j).value || '|' || l_values(j).desc_unit_measure;
                    
                        l_curr_idx := least(j + 1, l_values.count);
                    ELSIF l_time(i) > l_values(j).dt_vital_sign_read_tstz
                    THEN
                        EXIT;
                    END IF;
                END LOOP;
            
                FOR k IN l_init_count .. (l_current_fetus + 1)
                LOOP
                    l_array_fetus(k) := l_array_fetus(k) || l_sep;
                END LOOP;
            
                IF l_values(l_curr_idx).id_vital_sign <> r_vital.id_vital_sign
                THEN
                    EXIT;
                END IF;
            END LOOP;
        
        END LOOP;
    
        g_error := 'GET FINAL VS';
        IF l_count > 0
        THEN
            FOR i IN 1 .. (l_current_fetus + 1)
            LOOP
                IF l_array_fetus(i) IS NOT NULL
                THEN
                    o_val_vs.extend;
                    o_val_vs(l_count) := l_array_fetus(i) || l_sep;
                    l_count := l_count + 1;
                END IF;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_val_vs := table_varchar();
            RETURN error_handling_ext(i_lang,
                                      'GET_DELIVERY_TIME_EVENT',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      NULL,
                                      o_error);
    END get_delivery_time_event;

    /********************************************************************************************
    * Sets the delivery vital sign values
    *
    * @param i_lang                  language id
    * @param i_episode               episode id   
    * @param i_prof                  professional, software and institution ids
    * @param i_patient               patient ID   
    * @param i_pat_pregnancy         pregnancy id
    * @param i_flg_type              function call type: 'S' - set ; 'U' - update
    * @param i_vs_id                 vital sign IDs ('S') or vital sign values ID ('U')
    * @param i_vs_val                vital sign values
    * @param i_unit_meas             unit measures
    * @param i_vs_date               registration dates of the given values
    * @param i_fetus_number          the fetus number belonging to the vital sign values
    * @param i_prof_cat_type         professional category                
    *
    * @return o_vital_sign_read      vital sign values ID           
    * @return                        true or false on success or error
    *
    * @author                        Jos?Silva
    * @version                       1.0    
    * @since                         31-08-2007
    *
    * @author                        Jos?Silva
    * @version                       2.0    
    * @since                         30-05-2008
    ********************************************************************************************/

    FUNCTION set_delivery_vital_sign
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN vital_sign_read.id_episode%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_pat_pregnancy   IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_flg_type        IN VARCHAR2,
        i_vs_id           IN table_number,
        i_vs_val          IN table_number,
        i_unit_meas       IN table_number,
        i_vs_date         IN table_varchar,
        i_fetus_number    IN table_number,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_vital_sign_read OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret BOOLEAN;
    
        l_vital_sign_read table_number;
        l_type_set        VARCHAR2(1);
        l_type_upd        VARCHAR2(1);
    
        l_type_multichoice vital_sign.flg_fill_type%TYPE;
        l_flg_fill_type    vital_sign.flg_fill_type%TYPE;
    
        l_id_vital_sign_read vital_sign_read.id_vital_sign_read%TYPE;
        l_vs_aux             table_number;
        l_count              NUMBER := 1;
    
        l_id_vs_read_dt vital_sign_read.id_vital_sign_read%TYPE;
        l_error_vs_read EXCEPTION;
        l_msg_vs_read   sys_message.desc_message%TYPE;
    
        CURSOR c_vs_dates IS
            SELECT vr.id_vital_sign_read
              FROM vital_sign_read vr, vital_sign_pregnancy vp, vital_sign_read vr2, vital_sign_pregnancy vp2
             WHERE vp.id_pat_pregnancy = i_pat_pregnancy
               AND vp.id_vital_sign_read = vr.id_vital_sign_read
               AND vp2.id_pat_pregnancy = i_pat_pregnancy
               AND vp2.id_vital_sign_read = vr2.id_vital_sign_read
               AND vr2.id_vital_sign = vr.id_vital_sign
               AND vr2.dt_vital_sign_read_tstz = vr.dt_vital_sign_read_tstz
               AND vr2.id_vital_sign_read <> vr.id_vital_sign_read
               AND vp.fetus_number = vp2.fetus_number
               AND vr.flg_state != 'C'
               AND vr2.flg_state != 'C';
    
        CURSOR c_vs_relation(j NUMBER) IS
            SELECT vr2.id_vital_sign_read
              FROM vital_sign_read vr, vital_sign_read vr2, vital_sign_relation v, vital_sign_pregnancy vp
             WHERE vr.id_vital_sign_read = i_vs_id(j)
               AND vr2.id_patient = i_patient
               AND vp.id_vital_sign_read = vr2.id_vital_sign_read
               AND vr.dt_vital_sign_read_tstz = vr2.dt_vital_sign_read_tstz
               AND v.relation_domain = g_vs_rel_conc
               AND vr2.id_vital_sign <> vr.id_vital_sign
               AND vr2.id_vital_sign = v.id_vital_sign_detail
               AND v.id_vital_sign_parent = (SELECT id_vital_sign_parent
                                               FROM vital_sign_relation
                                              WHERE id_vital_sign_detail = vr.id_vital_sign
                                                AND relation_domain = g_vs_rel_conc)
               AND vr.id_vital_sign_read NOT IN (SELECT column_value
                                                   FROM TABLE(l_vs_aux));
    
        -- denormalization variables
        rows_vsr_out    table_varchar;
        e_process_event EXCEPTION;
    
        l_id_vital_sign_desc_in vital_sign_read.id_vital_sign_desc%TYPE;
        l_value_in              vital_sign_read.value%TYPE;
    
        l_exception EXCEPTION;
        l_error     t_error_out;
    
        l_vs_scales_elements table_number := table_number();
        l_dt_registry        VARCHAR2(20 CHAR);
    BEGIN
    
        l_type_set   := 'S';
        l_type_upd   := 'U';
        l_vs_aux     := table_number();
        rows_vsr_out := table_varchar();
    
        l_type_multichoice := 'V';
        l_msg_vs_read      := pk_message.get_message(i_lang, 'WOMAN_HEALTH_M009');
    
        IF i_flg_type = l_type_set
        THEN
            l_vs_scales_elements.extend(i_vs_id.count);
        
            g_error := 'SET EPIS VITAL SIGN';
            l_ret   := pk_vital_sign.set_epis_vital_sign(i_lang               => i_lang,
                                                         i_episode            => i_episode,
                                                         i_prof               => i_prof,
                                                         i_pat                => i_patient,
                                                         i_vs_id              => i_vs_id,
                                                         i_vs_val             => i_vs_val,
                                                         i_id_monit           => NULL,
                                                         i_unit_meas          => i_unit_meas,
                                                         i_vs_scales_elements => l_vs_scales_elements,
                                                         i_notes              => NULL,
                                                         i_prof_cat_type      => i_prof_cat_type,
                                                         i_dt_vs_read         => i_vs_date,
                                                         i_epis_triage        => NULL,
                                                         i_unit_meas_convert  => i_unit_meas,
                                                         i_fetus_vs           => i_fetus_number(1),
                                                         o_vital_sign_read    => l_vital_sign_read,
                                                         o_dt_registry        => l_dt_registry,
                                                         o_error              => l_error);
        
            IF NOT l_ret
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'START LOOP';
            FOR i IN 1 .. l_vital_sign_read.count
            LOOP
                g_error := 'INSERT INTO VITAL_SIGN_PREGNANCY';
                BEGIN
                    INSERT INTO vital_sign_pregnancy
                        (id_vital_sign_pregnancy, id_pat_pregnancy, id_vital_sign_read, fetus_number)
                    VALUES
                        (seq_vital_sign_pregnancy.nextval, i_pat_pregnancy, l_vital_sign_read(i), i_fetus_number(i));
                EXCEPTION
                    WHEN dup_val_on_index THEN
                        CONTINUE;
                END;
            END LOOP;
        END IF;
    
        OPEN c_vs_dates;
        FETCH c_vs_dates
            INTO l_id_vs_read_dt;
    
        IF l_id_vs_read_dt IS NOT NULL
        THEN
            RAISE l_error_vs_read;
        END IF;
    
        o_vital_sign_read := l_vital_sign_read;
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_error_vs_read THEN
            RETURN error_handling_ext(i_lang,
                                      'SET_DELIVERY_VITAL_SIGN',
                                      '',
                                      'WOMAN_HEALTH_M009',
                                      l_msg_vs_read,
                                      TRUE,
                                      'D',
                                      NULL,
                                      o_error);
        WHEN l_exception THEN
            RETURN error_handling_ext(i_lang,
                                      'SET_DELIVERY_VITAL_SIGN',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      NULL,
                                      o_error);
        WHEN OTHERS THEN
            o_vital_sign_read := table_number();
            RETURN error_handling_ext(i_lang,
                                      'SET_DELIVERY_VITAL_SIGN',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      NULL,
                                      o_error);
    END set_delivery_vital_sign;

    /********************************************************************************************
    * Gets the delivery event axis
    *
    * @param i_lang                  language id
    * @param i_patient               patient ID     
    * @param i_episode               episode ID     
    * @param i_prof                  professional, software and institution IDs 
    * @param i_pat_pregnancy         pregnancy id
    * @param i_flg_type              axis type 'G' - graph ; 'T' - table
    *
    * @return o_time                 time axis (graph type)
    * @return o_time_t               time axis (table type)   
    * @return o_sign_v               vital sign axis    
    * @return                        true or false on success or error
    *
    * @author                        Jos?Silva
    * @version                       1.0    
    * @since                         01-09-2007
    ********************************************************************************************/

    FUNCTION get_delivery_event_axis
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_flg_type      IN VARCHAR2,
        o_time          OUT NUMBER,
        o_time_t        OUT pk_types.cursor_type,
        o_sign_v        OUT pk_types.cursor_type,
        o_drug          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_birth_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_delivery_time NUMBER;
        l_max_limit     NUMBER;
        l_num_hours     table_number := table_number();
    
        l_fetus_number NUMBER;
    
        l_id_market market.id_market%TYPE;
        l_id_visit  visit.id_visit%TYPE;
    
        l_exception EXCEPTION;
        l_error     t_error_out;
        l_age       vital_sign_unit_measure.age_min%TYPE;
    
    BEGIN
    
        l_age := pk_patient.get_pat_age(i_lang, NULL, NULL, NULL, 'MONTHS', i_patient);
    
        l_delivery_time := pk_sysconfig.get_config('WOMAN_HEALTH_DELIVERY_TIME', i_prof); -- limite maximo no eixo das horas
    
        g_error := 'GET FETUS NUMBER';
        IF NOT get_fetus_number(i_lang, i_prof, i_pat_pregnancy, l_fetus_number, l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'GET BIRTH DATE';
        IF NOT get_dt_birth(i_lang, i_prof, i_pat_pregnancy, g_type_dt_birth_s, NULL, l_dt_birth_tstz, l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error    := 'GET VISIT ID';
        l_id_visit := pk_episode.get_id_visit(i_episode);
    
        g_error := 'GET ID_MARKET';
        SELECT i.id_market
          INTO l_id_market
          FROM institution i
         WHERE i.id_institution = i_prof.institution;
    
        g_error := 'GET MAX HOUR';
        IF NOT get_max_hour_graph(i_lang          => i_lang,
                                  i_prof          => i_prof,
                                  i_patient       => i_patient,
                                  i_episode       => i_episode,
                                  i_visit         => l_id_visit,
                                  i_pat_pregnancy => i_pat_pregnancy,
                                  i_fetus_number  => l_fetus_number,
                                  i_dt_birth      => l_dt_birth_tstz,
                                  i_flg_type      => i_flg_type,
                                  o_max_limit     => l_max_limit,
                                  o_num_hours     => l_num_hours,
                                  o_error         => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'OPEN CURSOR O_SIGN_V';
        OPEN o_sign_v FOR
            SELECT /*+use_concat*/
            DISTINCT vs.id_vital_sign,
                     vsp.fetus_number,
                     pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                     vsi.rank,
                     coalesce((SELECT gs.val_min
                                FROM graph_scale gs
                               WHERE gs.id_vital_sign = vs.id_vital_sign
                                 AND gs.flg_available = g_available
                                 AND gs.flg_type IN (g_grapfic_scale_p, g_grapfic_scale_d)
                                 AND gs.id_graph_scale IN
                                     (SELECT id_graph_scale
                                        FROM (SELECT gss.id_graph_scale, gss.id_vital_sign
                                                FROM graph_scale gss, graph_scale_inst gi
                                               WHERE gi.id_institution IN (i_prof.institution, 0)
                                                 AND gss.flg_available = g_available
                                                 AND gss.id_graph_scale = gi.id_graph_scale
                                                 AND gi.id_market IN (l_id_market, 0)
                                                 AND gss.flg_type IN (g_grapfic_scale_p, g_grapfic_scale_d)
                                               ORDER BY gi.id_institution DESC, gi.id_market DESC) g
                                       WHERE g.id_vital_sign = gs.id_vital_sign
                                         AND rownum = 1)),
                              (SELECT pk_vital_sign_core.get_vsum_val_min(i_lang            => i_lang,
                                                                          i_prof            => i_prof,
                                                                          i_id_vital_sign   => vs.id_vital_sign,
                                                                          i_id_unit_measure => vsi.id_unit_measure,
                                                                          i_id_institution  => i_prof.institution,
                                                                          i_id_software     => i_prof.software,
                                                                          i_age             => l_age)
                                 FROM dual)) val_min, -- os sinais vitais preenchidos por multichoice têm val_max e val_min parametrizados na tabela vital_sign
                     coalesce((SELECT gs.val_max
                                FROM graph_scale gs
                               WHERE gs.id_vital_sign = vs.id_vital_sign
                                 AND gs.flg_available = g_available
                                 AND gs.flg_type IN (g_grapfic_scale_p, g_grapfic_scale_d)
                                 AND gs.id_graph_scale IN
                                     (SELECT id_graph_scale
                                        FROM (SELECT gss.id_graph_scale, gss.id_vital_sign
                                                FROM graph_scale gss, graph_scale_inst gi
                                               WHERE gi.id_institution IN (i_prof.institution, 0)
                                                 AND gss.flg_available = g_available
                                                 AND gss.id_graph_scale = gi.id_graph_scale
                                                 AND gi.id_market IN (l_id_market, 0)
                                                 AND gss.flg_type IN (g_grapfic_scale_p, g_grapfic_scale_d)
                                               ORDER BY gi.id_institution DESC, gi.id_market DESC) g
                                       WHERE g.id_vital_sign = gs.id_vital_sign
                                         AND rownum = 1)),
                              (SELECT pk_vital_sign_core.get_vsum_val_max(i_lang            => i_lang,
                                                                          i_prof            => i_prof,
                                                                          i_id_vital_sign   => vs.id_vital_sign,
                                                                          i_id_unit_measure => vsi.id_unit_measure,
                                                                          i_id_institution  => i_prof.institution,
                                                                          i_id_software     => i_prof.software,
                                                                          i_age             => l_age)
                                 FROM dual)) val_max,
                     get_graph_color(vsi.color_grafh, eg.intern_name, vsp.fetus_number, l_fetus_number, vsi.flg_view) color_grafh,
                     --                            vsi.color_grafh,
                     vsi.color_text,
                     decode(vsp.fetus_number, NULL, '', 0, '', '(' || '#' || vsp.fetus_number || ') ') ||
                     decode(um.id_unit_measure,
                            NULL,
                            '',
                            '(' || pk_translation.get_translation(i_lang, um.code_unit_measure) || ')') desc_fetus_measure,
                     pk_translation.get_translation(i_lang, um.code_unit_measure) desc_unit_measure,
                     vsi.id_unit_measure,
                     decode(vsi.flg_view, g_view_delivery, 'Y', g_flg_view, 'N') flg_default,
                     'VS' flg_group
              FROM vital_sign_read      vsr,
                   vital_sign           vs,
                   vs_soft_inst         vsi,
                   unit_measure         um,
                   event                e,
                   event_group          eg,
                   vital_sign_pregnancy vsp
             WHERE (vs.id_vital_sign = vsr.id_vital_sign OR EXISTS
                    (SELECT 1
                       FROM vital_sign_relation vr
                      WHERE vr.id_vital_sign_parent = vs.id_vital_sign
                        AND vsr.id_vital_sign = vr.id_vital_sign_detail
                        AND vr.relation_domain = g_vs_rel_conc))
               AND vsr.flg_state = g_vs_read_active
               AND (vsr.value IS NOT NULL OR vsr.id_vital_sign_desc IS NOT NULL)
               AND ((SELECT pk_vital_sign_core.get_vsum_val_max(i_lang            => i_lang,
                                                                i_prof            => i_prof,
                                                                i_id_vital_sign   => vs.id_vital_sign,
                                                                i_id_unit_measure => vsi.id_unit_measure,
                                                                i_id_institution  => i_prof.institution,
                                                                i_id_software     => i_prof.software,
                                                                i_age             => l_age)
                       FROM dual) IS NOT NULL OR i_flg_type = g_type_table)
               AND vsi.id_vital_sign = vs.id_vital_sign
               AND vsi.id_software IN (i_prof.software, 0)
               AND vsi.id_institution IN (i_prof.institution, 0)
               AND vsi.flg_view IN (decode(i_flg_type, g_type_table, g_flg_view, g_view_delivery))
               AND um.id_unit_measure(+) = vsi.id_unit_measure
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND eg.intern_name IN (g_intern_name_delivery, g_intern_name_fetus)
               AND eg.id_event_group = e.id_event_group
               AND (e.id_group = vsr.id_vital_sign OR EXISTS
                    (SELECT 1
                       FROM vital_sign_relation vr
                      WHERE vr.id_vital_sign_parent = e.id_group
                        AND vsr.id_vital_sign = vr.id_vital_sign_detail
                        AND vr.relation_domain = g_vs_rel_conc))
               AND (vsr.id_vital_sign_desc IS NOT NULL OR vsr.value IS NOT NULL)
               AND vsp.id_vital_sign_read = vsr.id_vital_sign_read
               AND vsp.id_pat_pregnancy = i_pat_pregnancy
               AND vsp.fetus_number < l_fetus_number + 1
               AND vsr.dt_vital_sign_read_tstz >= l_dt_birth_tstz
               AND (NOT EXISTS (SELECT 0
                                  FROM vital_sign_relation vr
                                 WHERE vr.id_vital_sign_detail = vs.id_vital_sign
                                   AND vr.relation_domain = g_vs_rel_graph) OR i_flg_type = g_type_table)
             ORDER BY rank, id_vital_sign, fetus_number;
    
        g_error := 'GET DELIVERY DRUGS';
        IF NOT pk_api_pfh_clindoc_in.get_delivery_drug_presc(i_lang     => i_lang,
                                                             i_prof     => i_prof,
                                                             i_visit    => l_id_visit,
                                                             i_dt_birth => l_dt_birth_tstz,
                                                             o_drugs    => o_drug,
                                                             o_error    => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'CHECK I_FLG_TYPE';
        IF i_flg_type = g_type_graph
        THEN
            o_time := greatest(l_delivery_time, l_max_limit);
            pk_types.open_my_cursor(o_time_t);
        ELSIF i_flg_type = g_type_table
        THEN
            g_error := 'OPEN CURSOR O_TIME_T';
            OPEN o_time_t FOR
                SELECT /*+use_concat*/
                 pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) dt_vital_sign_read,
                 pk_date_utils.date_chr_space_tsz(i_lang,
                                                  vsr.dt_vital_sign_read_tstz,
                                                  i_prof.institution,
                                                  i_prof.software) short_dt_read,
                 pk_date_utils.date_char_hour_tsz(i_lang,
                                                  vsr.dt_vital_sign_read_tstz,
                                                  i_prof.institution,
                                                  i_prof.software) hour_read
                  FROM vital_sign_read      vsr,
                       vital_sign           vs,
                       vs_soft_inst         vsi,
                       event                e,
                       event_group          eg,
                       vital_sign_pregnancy vsp
                 WHERE (vs.id_vital_sign = vsr.id_vital_sign OR EXISTS
                        (SELECT 1
                           FROM vital_sign_relation vr
                          WHERE vr.id_vital_sign_parent = vs.id_vital_sign
                            AND vsr.id_vital_sign = vr.id_vital_sign_detail
                            AND vr.relation_domain = g_vs_rel_conc))
                   AND vs.flg_available = g_vs_avail
                   AND vsr.flg_state = g_vs_read_active
                   AND vsi.id_vital_sign = vs.id_vital_sign
                   AND vsi.id_software IN (i_prof.software, 0)
                   AND vsi.id_institution IN (i_prof.institution, 0)
                   AND vsi.flg_view IN (decode(i_flg_type, g_type_table, g_flg_view, g_view_delivery))
                   AND vsr.id_patient = i_patient
                   AND e.flg_group = 'VS'
                   AND eg.intern_name IN (g_intern_name_delivery, g_intern_name_fetus)
                   AND eg.id_event_group = e.id_event_group
                   AND (e.id_group = vsr.id_vital_sign OR EXISTS
                        (SELECT 1
                           FROM vital_sign_relation vr
                          WHERE vr.id_vital_sign_parent = e.id_group
                            AND vsr.id_vital_sign = vr.id_vital_sign_detail
                            AND vr.relation_domain = g_vs_rel_conc))
                   AND (vsr.id_vital_sign_desc IS NOT NULL OR vsr.value IS NOT NULL)
                   AND vsp.id_vital_sign_read = vsr.id_vital_sign_read
                   AND vsp.id_pat_pregnancy = i_pat_pregnancy
                   AND vsp.fetus_number < l_fetus_number + 1
                   AND vsr.dt_vital_sign_read_tstz >= l_dt_birth_tstz
                 GROUP BY vsr.dt_vital_sign_read_tstz
                
                UNION
                
                SELECT pk_date_utils.date_send_tsz(i_lang, drug_t.column_value, i_prof) dt_vital_sign_read,
                       pk_date_utils.to_char_insttimezone(i_prof, drug_t.column_value, 'DD Mon') short_dt_read,
                       (pk_date_utils.to_char_insttimezone(i_prof, drug_t.column_value, 'HH24:MI') || 'h') hour_read
                  FROM TABLE(pk_api_pfh_clindoc_in.get_delivery_drug_time_t(i_lang, i_prof, l_id_visit, l_dt_birth_tstz)) drug_t
                 ORDER BY dt_vital_sign_read;
        
        ELSE
            pk_types.open_my_cursor(o_time_t);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(o_sign_v);
            pk_types.open_my_cursor(o_time_t);
            pk_types.open_my_cursor(o_drug);
            RETURN error_handling_ext(i_lang,
                                      'GET_DELIVERY_EVENT_AXIS',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      NULL,
                                      o_error);
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_sign_v);
            pk_types.open_my_cursor(o_time_t);
            pk_types.open_my_cursor(o_drug);
            RETURN error_handling_ext(i_lang,
                                      'GET_DELIVERY_EVENT_AXIS',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      NULL,
                                      o_error);
    END get_delivery_event_axis;

    /********************************************************************************************
    * Gets all vital sign delivery events
    *
    * @param i_lang                  language id
    * @param i_patient               patient ID     
    * @param i_prof                  professional, software and institution ids 
    * @param i_pat_pregnancy         pregnancy id 
    * @param i_flg_type              axis type 'G' - graph ; 'T' - table                  
    *        
    * @return o_val_vs               vital sign values    
    * @return                        true or false on success or error
    *
    * @author                        Jos?Silva
    * @version                       1.0    
    * @since                         03-09-2007
    ********************************************************************************************/
    FUNCTION get_delivery_vs
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_flg_type      IN VARCHAR2,
        o_val_vs        OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_max_limit     NUMBER;
        l_num_hours     table_number := table_number();
        l_dt_birth_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_fetus_number  NUMBER;
    
        l_count  NUMBER;
        l_count2 NUMBER;
        l_sep    VARCHAR2(1);
    
        l_array_fetus table_varchar;
    
        l_id_visit visit.id_visit%TYPE;
        l_age      vital_sign_unit_measure.age_min%TYPE;
    
        CURSOR c_time IS
            SELECT /*+use_concat*/
             vsr.dt_vital_sign_read_tstz dt_vital_sign_read
              FROM vital_sign_read      vsr,
                   vital_sign           vs,
                   vs_soft_inst         vsi,
                   event                e,
                   event_group          eg,
                   vital_sign_pregnancy vsp
             WHERE (vs.id_vital_sign = vsr.id_vital_sign OR EXISTS
                    (SELECT 1
                       FROM vital_sign_relation vr
                      WHERE vr.id_vital_sign_parent = vs.id_vital_sign
                        AND vsr.id_vital_sign = vr.id_vital_sign_detail
                        AND vr.relation_domain = g_vs_rel_conc))
               AND vsr.flg_state = g_vs_read_active
               AND vsi.id_vital_sign = vs.id_vital_sign
               AND vsi.id_software IN (i_prof.software, 0)
               AND vsi.id_institution IN (i_prof.institution, 0)
               AND vsi.flg_view IN (decode(i_flg_type, g_type_table, g_flg_view, g_view_delivery))
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND eg.intern_name IN (g_intern_name_delivery, g_intern_name_fetus)
               AND eg.id_event_group = e.id_event_group
               AND (e.id_group = vsr.id_vital_sign OR EXISTS
                    (SELECT 1
                       FROM vital_sign_relation vr
                      WHERE vr.id_vital_sign_parent = e.id_group
                        AND vsr.id_vital_sign = vr.id_vital_sign_detail
                        AND vr.relation_domain = g_vs_rel_conc))
               AND (vsr.id_vital_sign_desc IS NOT NULL OR vsr.value IS NOT NULL)
               AND vsp.id_vital_sign_read = vsr.id_vital_sign_read
               AND vsp.id_pat_pregnancy = i_pat_pregnancy
               AND vsp.fetus_number < l_fetus_number + 1
               AND vsr.dt_vital_sign_read_tstz >= l_dt_birth_tstz
             GROUP BY vsr.dt_vital_sign_read_tstz
             ORDER BY dt_vital_sign_read;
    
        CURSOR c_vital IS
            SELECT /*+use_concat*/
             vs.id_vital_sign, vsi.rank, vr.relation_domain
              FROM vital_sign_read      vsr,
                   vital_sign           vs,
                   vs_soft_inst         vsi,
                   vital_sign_desc      vdesc,
                   event                e,
                   event_group          eg,
                   vital_sign_pregnancy vsp,
                   vital_sign_relation  vr
             WHERE (vs.id_vital_sign = vsr.id_vital_sign OR EXISTS
                    (SELECT 1
                       FROM vital_sign_relation vr2
                      WHERE vr2.id_vital_sign_parent = vs.id_vital_sign
                        AND vsr.id_vital_sign = vr2.id_vital_sign_detail
                        AND vr2.relation_domain = g_vs_rel_conc))
               AND vsr.flg_state = g_vs_read_active
               AND (vsr.value IS NOT NULL OR vsr.id_vital_sign_desc IS NOT NULL)
                  -- Jos?Brito 18/12/2008 ALERT-9992
                  -- Support for vital signs selected in multichoice
               AND vsr.id_vital_sign_desc = vdesc.id_vital_sign_desc(+)
               AND vdesc.flg_available(+) = 'Y'
                  --
               AND ((SELECT pk_vital_sign_core.get_vsum_val_max(i_lang            => i_lang,
                                                                i_prof            => i_prof,
                                                                i_id_vital_sign   => vs.id_vital_sign,
                                                                i_id_unit_measure => vsi.id_unit_measure,
                                                                i_id_institution  => i_prof.institution,
                                                                i_id_software     => i_prof.software,
                                                                i_age             => l_age)
                       FROM dual) IS NOT NULL OR i_flg_type = g_type_table)
               AND vsi.id_vital_sign = vs.id_vital_sign
               AND vsi.id_software IN (i_prof.software, 0)
               AND vsi.id_institution IN (i_prof.institution, 0)
               AND vsi.flg_view IN (decode(i_flg_type, g_type_table, g_flg_view, g_view_delivery))
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND eg.intern_name IN (g_intern_name_delivery, g_intern_name_fetus)
               AND eg.id_event_group = e.id_event_group
               AND (e.id_group = vsr.id_vital_sign OR EXISTS
                    (SELECT 1
                       FROM vital_sign_relation vr2
                      WHERE vr2.id_vital_sign_parent = e.id_group
                        AND vsr.id_vital_sign = vr2.id_vital_sign_detail
                        AND vr2.relation_domain = g_vs_rel_conc))
               AND vsp.id_vital_sign_read = vsr.id_vital_sign_read
               AND vsp.id_pat_pregnancy = i_pat_pregnancy
               AND vsp.fetus_number < l_fetus_number + 1
               AND vr.id_vital_sign_parent(+) = vs.id_vital_sign
               AND vr.relation_domain(+) = g_vs_rel_conc
               AND vsr.dt_vital_sign_read_tstz >= l_dt_birth_tstz
             GROUP BY vs.id_vital_sign, vsi.rank, vr.relation_domain
             ORDER BY vsi.rank, vs.id_vital_sign;
    
        CURSOR c_values IS
            SELECT pk_delivery.get_reg_value(i_lang,
                                             i_prof,
                                             i_patient,
                                             i_pat_pregnancy,
                                             vsr.id_vital_sign,
                                             vsr3.id_vital_sign_parent,
                                             vsr.value,
                                             vdesc.code_abbreviation,
                                             vdesc.code_vital_sign_desc,
                                             vdesc.icon,
                                             vdesc.value,
                                             i_flg_type,
                                             vsr.dt_vital_sign_read_tstz,
                                             vsp.fetus_number) VALUE,
                   vsr.id_vital_sign_read,
                   'A' reg,
                   nvl(vsr3.relation_domain, 'S') flg_reg,
                   decode(i_flg_type,
                          g_type_graph,
                          (pk_date_utils.diff_timestamp(vsr.dt_vital_sign_read_tstz,
                                                        pk_date_utils.add_to_ltstz(l_dt_birth_tstz,
                                                                                   get_hour_delivery(i_lang,
                                                                                                     i_prof,
                                                                                                     l_num_hours,
                                                                                                     l_dt_birth_tstz,
                                                                                                     vsr.dt_vital_sign_read_tstz) - 1,
                                                                                   'HOUR')) * 24),
                          pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof)) time_value,
                   nvl(vsp.fetus_number, 0) fetus_number,
                   pk_date_utils.date_char_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof.institution, i_prof.software) dt_read,
                   get_hour_delivery(i_lang, i_prof, l_num_hours, l_dt_birth_tstz, vsr.dt_vital_sign_read_tstz) hour_vs,
                   nvl(vsr3.id_vital_sign_parent, vsr.id_vital_sign) id_vital_sign,
                   vsr.dt_vital_sign_read_tstz
              FROM vital_sign_read      vsr,
                   vital_sign_desc      vdesc,
                   vital_sign_pregnancy vsp,
                   vital_sign_relation  vsr3,
                   vs_soft_inst         vsi
             WHERE vsr.flg_state = g_vs_read_active
                  -- Jos?Brito 18/12/2008 ALERT-9992
                  -- Support for vital signs selected in multichoice
               AND vsr.id_vital_sign_desc = vdesc.id_vital_sign_desc(+)
                  --
               AND vsr.id_vital_sign = vdesc.id_vital_sign(+)
               AND vsr.id_vital_sign = vsr3.id_vital_sign_detail(+)
               AND vsr3.relation_domain(+) = g_vs_rel_conc
               AND vsr.id_patient = i_patient
               AND vsi.id_vital_sign = nvl(vsr3.id_vital_sign_parent, vsr.id_vital_sign)
               AND vsi.id_software IN (i_prof.software, 0)
               AND vsi.id_institution IN (i_prof.institution, 0)
               AND vsi.flg_view IN (decode(i_flg_type, g_type_table, g_flg_view, g_view_delivery))
               AND (vsr.id_vital_sign_desc IS NOT NULL OR vsr.value IS NOT NULL)
               AND vsp.id_pat_pregnancy = i_pat_pregnancy
               AND vsp.fetus_number < l_fetus_number + 1
               AND vsp.id_vital_sign_read = vsr.id_vital_sign_read
               AND (NOT EXISTS (SELECT 0
                                  FROM vital_sign_relation vr
                                 WHERE vr.id_vital_sign_detail = vsr.id_vital_sign
                                   AND vr.relation_domain = g_vs_rel_graph) OR i_flg_type = g_type_table)
               AND nvl(vsr3.rank, -1) = nvl(decode(i_flg_type,
                                                   g_type_table,
                                                   (SELECT MAX(rank)
                                                      FROM vital_sign_relation
                                                     WHERE id_vital_sign_parent = vsr3.id_vital_sign_parent
                                                       AND relation_domain = g_vs_rel_conc),
                                                   vsr3.rank),
                                            -1)
             ORDER BY vsi.rank, id_vital_sign, hour_vs, vsr.dt_vital_sign_read_tstz;
    
        l_exception EXCEPTION;
        l_error     t_error_out;
    
        TYPE dataset_time IS TABLE OF c_time%ROWTYPE INDEX BY PLS_INTEGER;
        TYPE dataset_vital IS TABLE OF c_vital%ROWTYPE INDEX BY PLS_INTEGER;
        TYPE dataset_values IS TABLE OF c_values%ROWTYPE INDEX BY PLS_INTEGER;
    
        l_time     dataset_time;
        l_vital    dataset_vital;
        l_values   dataset_values;
        l_curr_idx PLS_INTEGER := 1;
    
    BEGIN
        l_age := pk_patient.get_pat_age(i_lang, NULL, NULL, NULL, 'MONTHS', i_patient);
    
        g_error := 'GET FETUS NUMBER';
        IF NOT get_fetus_number(i_lang, i_prof, i_pat_pregnancy, l_fetus_number, l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'GET BIRTH DATE';
        IF NOT get_dt_birth(i_lang, i_prof, i_pat_pregnancy, g_type_dt_birth_s, NULL, l_dt_birth_tstz, l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF i_flg_type = g_type_graph
        THEN
            g_error := 'GET MAX HOUR';
            IF NOT get_max_hour_graph(i_lang          => i_lang,
                                      i_prof          => i_prof,
                                      i_patient       => i_patient,
                                      i_episode       => NULL,
                                      i_visit         => NULL,
                                      i_pat_pregnancy => i_pat_pregnancy,
                                      i_fetus_number  => l_fetus_number,
                                      i_dt_birth      => l_dt_birth_tstz,
                                      i_flg_type      => i_flg_type,
                                      o_max_limit     => l_max_limit,
                                      o_num_hours     => l_num_hours,
                                      o_error         => l_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSE
            g_error := 'GET TIME RECORDS';
            OPEN c_time;
            FETCH c_time BULK COLLECT
                INTO l_time;
            CLOSE c_time;
        END IF;
    
        l_sep := ';';
    
        g_error       := 'INIT';
        o_val_vs      := table_varchar(); -- inicialização do vector
        l_array_fetus := table_varchar();
        FOR i IN 1 .. (l_fetus_number + 2)
        LOOP
            l_array_fetus.extend;
        END LOOP;
    
        g_error := 'GET VITAL SIGNS';
        OPEN c_vital;
        FETCH c_vital BULK COLLECT
            INTO l_vital;
        CLOSE c_vital;
    
        g_error := 'GET VS VALUES';
        OPEN c_values;
        FETCH c_values BULK COLLECT
            INTO l_values;
        CLOSE c_values;
    
        l_count    := 0;
        l_curr_idx := 1;
    
        g_error := 'GET CURSOR C_VITAL';
        FOR vital_idx IN 1 .. l_vital.count
        LOOP
        
            IF l_count > 0
            THEN
                FOR i IN 1 .. (l_fetus_number + 1)
                LOOP
                    o_val_vs.extend;
                    o_val_vs(l_count) := l_array_fetus(i) || l_sep;
                    l_count := l_count + 1;
                END LOOP;
            ELSE
                l_count := l_count + 1;
            END IF;
        
            FOR i IN 1 .. (l_fetus_number + 1)
            LOOP
                l_array_fetus(i) := NULL;
                l_array_fetus(i) := i - 1 || l_sep || l_vital(vital_idx).id_vital_sign || l_sep;
            END LOOP;
        
            IF i_flg_type = g_type_graph
            THEN
            
                l_count2 := 1;
                g_error  := 'GET CURSOR C_TIME';
                FOR i IN 1 .. l_num_hours.count
                LOOP
                    g_error := 'IGNORE EMPTY CELLS';
                    FOR j IN l_count2 .. l_num_hours(i) - 1
                    LOOP
                        FOR k IN 1 .. (l_fetus_number + 1)
                        LOOP
                            l_array_fetus(k) := l_array_fetus(k) || l_sep;
                        END LOOP;
                    END LOOP;
                    l_count2 := l_num_hours(i) + 1;
                
                    g_error := 'GET CURSOR C_VALUES' || l_vital(vital_idx).id_vital_sign || '-' || l_num_hours(i) || '-' ||
                               l_curr_idx;
                    FOR j IN l_curr_idx .. l_values.count
                    LOOP
                        IF greatest(l_num_hours(i), 1) = l_values(j).hour_vs
                           AND l_values(j).fetus_number < (l_fetus_number + 1)
                           AND l_values(j).id_vital_sign = l_vital(vital_idx).id_vital_sign
                        THEN
                            l_array_fetus(l_values(j).fetus_number + 1) := l_array_fetus(l_values(j).fetus_number + 1) || l_values(j).id_vital_sign_read || '|' || l_values(j).flg_reg || '|' || l_values(j).reg || '|' || l_values(j).value || '|' || l_values(j).time_value || '|' || l_values(j).dt_read || '@';
                        
                            l_curr_idx := least(j + 1, l_values.count);
                        ELSIF l_num_hours(i) > l_values(j).hour_vs
                        THEN
                            EXIT;
                        END IF;
                    END LOOP;
                
                    IF l_num_hours(i) > 0
                    THEN
                        FOR k IN 1 .. (l_fetus_number + 1)
                        LOOP
                            l_array_fetus(k) := l_array_fetus(k) || l_sep;
                        END LOOP;
                    END IF;
                
                    IF l_values(l_curr_idx).id_vital_sign <> l_vital(vital_idx).id_vital_sign
                    THEN
                        EXIT;
                    END IF;
                
                END LOOP;
            
            ELSIF i_flg_type = g_type_table
            THEN
            
                g_error := 'GET CURSOR C_TIME';
                FOR i IN 1 .. l_time.count
                LOOP
                
                    g_error := 'GET CURSOR C_VALUES' || l_vital(vital_idx).id_vital_sign;
                    FOR j IN l_curr_idx .. l_values.count
                    LOOP
                        IF l_time(i).dt_vital_sign_read = l_values(j).dt_vital_sign_read_tstz
                            AND l_values(j).fetus_number < (l_fetus_number + 1)
                            AND l_values(j).id_vital_sign = l_vital(vital_idx).id_vital_sign
                        THEN
                            l_array_fetus(l_values(j).fetus_number + 1) := l_array_fetus(l_values(j).fetus_number + 1) || l_values(j).id_vital_sign_read || '|' || l_values(j).flg_reg || '|' || l_values(j).reg || '|' || l_values(j).value || '|' || l_values(j).time_value || '@';
                        
                            l_curr_idx := least(j + 1, l_values.count);
                        END IF;
                    END LOOP;
                
                    FOR k IN 1 .. (l_fetus_number + 1)
                    LOOP
                        l_array_fetus(k) := l_array_fetus(k) || l_sep;
                    END LOOP;
                
                    IF l_values(l_curr_idx).id_vital_sign <> l_vital(vital_idx).id_vital_sign
                    THEN
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        END LOOP;
    
        g_error := 'GET FINAL VS';
        IF l_count > 0
        THEN
            FOR i IN 1 .. (l_fetus_number + 1)
            LOOP
                o_val_vs.extend;
                o_val_vs(l_count) := l_array_fetus(i) || l_sep;
                l_count := l_count + 1;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            o_val_vs := table_varchar();
            RETURN error_handling_ext(i_lang,
                                      'GET_DELIVERY_VS',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      NULL,
                                      o_error);
        WHEN OTHERS THEN
            o_val_vs := table_varchar();
            RETURN error_handling_ext(i_lang, 'GET_DELIVERY_VS', g_error, SQLCODE, SQLERRM, FALSE, 'S', NULL, o_error);
    END get_delivery_vs;

    /********************************************************************************************
    * Gets all drug prescriptions during delivery period
    *
    * @param i_lang                  language ID
    * @param i_episode               episode ID       
    * @param i_prof                  professional, software and institution ids 
    * @param i_patient               patient ID     
    * @param i_pat_pregnancy         pregnancy id
    * @param i_flg_type              axis type 'G' - graph ; 'T' - table                     
    *        
    * @return o_drug                 drug prescriptions    
    * @return                        true or false on success or error
    *
    * @author                        Jos?Silva
    * @version                       1.0    
    * @since                         03-09-2007
    ********************************************************************************************/

    FUNCTION get_delivery_drug
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN vital_sign_read.id_episode%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_flg_type      IN VARCHAR2,
        o_drug          OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_hours_in_a_day CONSTANT NUMBER(6) := 24;
    
        l_max_limit     NUMBER;
        l_num_hours     table_number := table_number();
        l_dt_birth_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_count  NUMBER;
        l_count2 NUMBER;
        l_sep    VARCHAR2(1);
    
        l_array_val VARCHAR2(4000);
        l_time      pk_types.cursor_type;
        l_drug      pk_types.cursor_type;
        l_drug_val  pk_types.cursor_type;
    
        TYPE t_tab_drug_val IS TABLE OF pk_api_pfh_clindoc_in.t_delivery_rec_drug_val INDEX BY PLS_INTEGER;
    
        l_tab_time table_timestamp_tstz := table_timestamp_tstz();
        l_tab_drug table_varchar := table_varchar();
        l_tab_val  t_tab_drug_val;
        l_curr_idx PLS_INTEGER := 1;
    
        l_id_visit visit.id_visit%TYPE;
    
        l_exception EXCEPTION;
        l_error     t_error_out;
    BEGIN
    
        g_error    := 'GET VISIT ID';
        l_id_visit := pk_episode.get_id_visit(i_episode);
    
        g_error := 'GET BIRTH DATE';
        IF NOT get_dt_birth(i_lang, i_prof, i_pat_pregnancy, g_type_dt_birth_s, NULL, l_dt_birth_tstz, l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'GET GRUG PARAM';
        IF NOT pk_api_pfh_clindoc_in.get_delivery_drug_param(i_lang     => i_lang,
                                                             i_prof     => i_prof,
                                                             i_visit    => l_id_visit,
                                                             i_dt_birth => l_dt_birth_tstz,
                                                             o_drug     => l_drug,
                                                             o_error    => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        FETCH l_drug BULK COLLECT
            INTO l_tab_drug;
        CLOSE l_drug;
    
        IF i_flg_type = g_type_graph
        THEN
            g_error := 'GET MAX HOUR';
            IF NOT get_max_hour_graph(i_lang          => i_lang,
                                      i_prof          => i_prof,
                                      i_patient       => i_patient,
                                      i_episode       => i_episode,
                                      i_visit         => l_id_visit,
                                      i_pat_pregnancy => i_pat_pregnancy,
                                      i_fetus_number  => NULL,
                                      i_dt_birth      => l_dt_birth_tstz,
                                      i_flg_type      => i_flg_type,
                                      o_max_limit     => l_max_limit,
                                      o_num_hours     => l_num_hours,
                                      o_error         => l_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSE
            g_error := 'GET DRUG TIME';
            IF NOT pk_api_pfh_clindoc_in.get_delivery_drug_time(i_lang     => i_lang,
                                                                i_prof     => i_prof,
                                                                i_visit    => l_id_visit,
                                                                i_dt_birth => l_dt_birth_tstz,
                                                                o_time     => l_time,
                                                                o_error    => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            FETCH l_time BULK COLLECT
                INTO l_tab_time;
            CLOSE l_time;
        END IF;
    
        g_error := 'GET DRUG VALUE';
        IF NOT pk_api_pfh_clindoc_in.get_delivery_drug_val(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_visit     => l_id_visit,
                                                           i_num_hours => l_num_hours,
                                                           i_dt_birth  => l_dt_birth_tstz,
                                                           i_flg_type  => i_flg_type,
                                                           o_drug_val  => l_drug_val,
                                                           o_error     => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        FETCH l_drug_val BULK COLLECT
            INTO l_tab_val;
        CLOSE l_drug_val;
    
        l_count := 0;
        l_sep   := ';';
    
        g_error := 'INICIALIZAÇÃO';
        o_drug  := table_varchar(); -- inicialização do vector
    
        g_error := 'GET CURSOR C_DRUG';
        FOR drug_idx IN 1 .. l_tab_drug.count
        LOOP
        
            IF l_count > 0
            THEN
                o_drug.extend;
                o_drug(l_count) := l_array_val || l_sep;
            END IF;
        
            l_count := l_count + 1;
        
            l_array_val := l_tab_drug(drug_idx) || l_sep;
            l_count2    := 1;
        
            IF i_flg_type = g_type_graph
            THEN
            
                g_error := 'GET CURSOR C_TIME';
                FOR i IN 1 .. l_num_hours.count
                LOOP
                
                    g_error := 'IGNORE EMPTY CELLS';
                    FOR j IN l_count2 .. l_num_hours(i) - 1
                    LOOP
                        l_array_val := l_array_val || l_sep;
                    END LOOP;
                
                    l_count2 := l_num_hours(i) + 1;
                
                    g_error := 'GET CURSOR C_VALUES';
                    FOR j IN l_curr_idx .. l_tab_val.count
                    LOOP
                        IF greatest(l_num_hours(i), 1) = l_tab_val(j).hour_vs
                           AND l_tab_val(j).id_drug = l_tab_drug(drug_idx)
                        THEN
                        
                            l_array_val := l_array_val || l_tab_val(j).id_drug_presc_plan || '|' || l_tab_val(j).flg_reg || '|' || l_tab_val(j).reg || '|' || l_tab_val(j).value || '|' || l_tab_val(j).icon || '|' || l_tab_val(j).time_value || '|' ||
                                           get_delivery_duration_hours(i_lang,
                                                                       i_prof,
                                                                       l_tab_val       (j).dt_begin,
                                                                       l_tab_val       (j).dt_end,
                                                                       l_hours_in_a_day,
                                                                       l_tab_val       (j).flg_take_type) || '|' || l_tab_val(j).dt_read || '@';
                        
                            l_curr_idx := least(j + 1, l_tab_val.count);
                        ELSIF l_num_hours(i) > l_tab_val(j).hour_vs
                        THEN
                            EXIT;
                        END IF;
                    END LOOP;
                
                    IF l_num_hours(i) > 0
                    THEN
                        l_array_val := l_array_val || l_sep;
                    END IF;
                
                    IF l_tab_val(l_curr_idx).id_drug != l_tab_drug(drug_idx)
                    THEN
                        EXIT;
                    END IF;
                
                END LOOP;
            ELSIF i_flg_type = g_type_table
            THEN
            
                g_error := 'GET CURSOR C_TIME';
                FOR i IN 1 .. l_tab_time.count
                LOOP
                
                    g_error := 'GET CURSOR C_VALUES';
                    FOR j IN l_curr_idx .. l_tab_val.count
                    LOOP
                        IF l_tab_time(i) = l_tab_val(j).dt_reg
                           AND l_tab_val(j).id_drug = l_tab_drug(drug_idx)
                        THEN
                            l_array_val := l_array_val || l_tab_val(j).id_drug_presc_plan || '|' || l_tab_val(j).flg_reg || '|' || l_tab_val(j).reg || '|' || l_tab_val(j).value || '|' || 'X' || '|' || l_tab_val(j).time_value || '|' || l_tab_val(j).dt_read || '@';
                        
                            l_curr_idx := least(j + 1, l_tab_val.count);
                        ELSIF l_tab_time(i) > l_tab_val(j).dt_reg
                        THEN
                            EXIT;
                        END IF;
                    END LOOP;
                
                    l_array_val := l_array_val || l_sep;
                
                    IF l_tab_val(l_curr_idx).id_drug != l_tab_drug(drug_idx)
                    THEN
                        EXIT;
                    END IF;
                END LOOP;
            
            END IF;
        END LOOP;
    
        g_error := 'GET FINAL DRUG';
        IF l_count > 0
        THEN
            o_drug.extend;
            o_drug(l_count) := l_array_val || l_sep;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            o_drug := table_varchar();
            RETURN error_handling_ext(i_lang,
                                      'GET_DELIVERY_DRUG',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      NULL,
                                      o_error);
        WHEN OTHERS THEN
            o_drug := table_varchar();
            RETURN error_handling_ext(i_lang,
                                      'GET_DELIVERY_DRUG',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      NULL,
                                      o_error);
    END get_delivery_drug;

    /********************************************************************************************
    * Checks if a doc area has registers in a specified delivery associated to a given professional.
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param i_doc_area            doc area id 
    * @param i_pat_pregnancy       pregnancy id 
    * @param i_child_number        child number
    * @param o_last_prof_epis_doc  Last documentation episode ID to profissional      
    * @param o_flg_data            Y if there are data, F when no date found
    * @param o_error               Error message
    *                        
    * @return                      true or false on success or error
    *
    * @author                  Jos?Silva
    * @version                       1.0                      
    * @since                   05-09-2007
    **********************************************************************************************/
    FUNCTION get_prof_doc_delivery_exists
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_child_number       IN epis_doc_delivery.child_number%TYPE,
        o_last_prof_epis_doc OUT epis_documentation.id_epis_documentation%TYPE,
        o_flg_data           OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_intern_name_child summary_page_section.internal_name%TYPE;
        l_id_doc_area       doc_area.id_doc_area%TYPE;
        l_area_child        summary_page_section.id_doc_area%TYPE;
        l_child_number      epis_doc_delivery.child_number%TYPE;
    
        CURSOR c_last_epis_doc IS
            SELECT ed.id_epis_documentation, ed.id_doc_area, edoc.child_number
              FROM epis_documentation ed, epis_doc_delivery edoc, episode e
             WHERE e.id_visit = (SELECT e2.id_visit
                                   FROM episode e2
                                  WHERE e2.id_episode = i_episode)
               AND ed.id_episode = e.id_episode
               AND ed.id_doc_area = i_doc_area
               AND ed.id_professional = i_prof.id
               AND ed.id_epis_documentation = edoc.id_epis_documentation
               AND edoc.id_pat_pregnancy = i_pat_pregnancy
               AND ed.flg_status = g_active
               AND ed.dt_creation_tstz =
                   (SELECT MAX(ed1.dt_creation_tstz)
                      FROM epis_documentation ed1, epis_doc_delivery edoc2, episode e2
                     WHERE e2.id_visit = (SELECT e3.id_visit
                                            FROM episode e3
                                           WHERE e3.id_episode = i_episode)
                       AND ed1.id_episode = e2.id_episode
                       AND ed1.id_professional = i_prof.id
                       AND ed1.id_doc_area = i_doc_area
                       AND ed1.flg_status = g_active
                       AND ed1.id_epis_documentation = edoc2.id_epis_documentation
                       AND edoc2.id_pat_pregnancy = i_pat_pregnancy
                       AND (edoc2.child_number = i_child_number OR edoc2.child_number IS NULL));
    BEGIN
    
        l_intern_name_child := 'Born child';
    
        g_error := 'GET AREA CHILD';
        SELECT sps.id_doc_area
          INTO l_area_child
          FROM summary_page_section sps
         WHERE sps.internal_name = l_intern_name_child;
    
        g_error := 'OPEN C_LAST_EPIS_DOC';
        OPEN c_last_epis_doc;
        FETCH c_last_epis_doc
            INTO o_last_prof_epis_doc, l_id_doc_area, l_child_number;
        IF c_last_epis_doc%FOUND
           AND (l_id_doc_area <> l_area_child OR (l_id_doc_area = l_area_child AND l_child_number = i_child_number) OR
           l_child_number IS NULL)
        THEN
            o_flg_data := 'Y';
        ELSE
            o_flg_data           := 'N';
            o_last_prof_epis_doc := NULL;
        END IF;
        CLOSE c_last_epis_doc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang,
                                      'GET_PROF_DOC_DELIVERY_EXISTS',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      NULL,
                                      o_error);
    END get_prof_doc_delivery_exists;

    /********************************************************************************************
    * Returns the professional who registered the last change (and the respective date) 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                the episode ID
    * @param i_doc_area               Array with the doc area ID
    * @param i_pat_pregnancy          Pregnancy id    
    * @param o_last_update            Cursor containing the last update register
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Jos?Silva
    * @version                        1.0    
    * @since                          05-09-2007
    **********************************************************************************************/
    FUNCTION get_delivery_doc_last_update
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_doc_area      IN table_number,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_last_update   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN CURSOR O_LAST_UPDATE';
        OPEN o_last_update FOR
            SELECT pk_message.get_message(i_lang, 'DOCUMENTATION_T001') title,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_last_update_tstz, i_prof) dt_last_update,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_prof_last_update) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ed.id_prof_last_update,
                                                    ed.dt_last_update_tstz,
                                                    ed.id_episode) desc_speciality,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, ed.dt_last_update_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang, ed.dt_last_update_tstz, i_prof.institution, i_prof.software) hour_target,
                   pk_date_utils.date_char_tsz(i_lang, ed.dt_last_update_tstz, i_prof.institution, i_prof.software) date_hour_target
              FROM epis_documentation ed, epis_doc_delivery edoc, episode e
             WHERE e.id_visit = (SELECT e2.id_visit
                                   FROM episode e2
                                  WHERE e2.id_episode = i_episode)
               AND ed.id_episode = e.id_episode
               AND ed.id_doc_area IN (SELECT *
                                        FROM TABLE(i_doc_area))
               AND ed.id_epis_documentation = edoc.id_epis_documentation
               AND edoc.id_pat_pregnancy = i_pat_pregnancy
               AND ed.dt_last_update_tstz = (SELECT MAX(ed1.dt_last_update_tstz)
                                               FROM epis_documentation ed1, epis_doc_delivery edoc2, episode e2
                                              WHERE e2.id_visit = (SELECT e3.id_visit
                                                                     FROM episode e3
                                                                    WHERE e3.id_episode = i_episode)
                                                AND ed1.id_episode = e2.id_episode
                                                AND ed1.id_doc_area IN (SELECT *
                                                                          FROM TABLE(i_doc_area))
                                                AND ed1.id_epis_documentation = edoc2.id_epis_documentation
                                                AND edoc2.id_pat_pregnancy = i_pat_pregnancy);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_last_update);
            RETURN error_handling_ext(i_lang,
                                      'GET_DELIVERY_DOC_LAST_UPDATE',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      NULL,
                                      o_error);
    END get_delivery_doc_last_update;

    /********************************************************************************************
    * Returns the statics lines presented in the delivery graph
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID) 
    *                        
    * @return o_lines                 Static lines
    * @return                         true or false on success or error
    * 
    * @author                         Jos?Silva
    * @version                        1.0    
    * @since                          07-09-2007
    **********************************************************************************************/
    FUNCTION get_delivery_graph_lines
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_lines OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_domain_graph sys_domain.code_domain%TYPE;
    
    BEGIN
    
        l_domain_graph := 'WOMAN_HEALTH.DELIVERY_GRAPH';
    
        g_error := 'OPEN CURSOR O_LINES';
        OPEN o_lines FOR
            SELECT sd.desc_val line_message, pk_sysconfig.get_config(l_domain_graph || '_' || sd.val, i_prof) coords
              FROM sys_domain sd
             WHERE sd.code_domain = l_domain_graph
               AND sd.id_language = i_lang
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.flg_available = g_available
             ORDER BY sd.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_lines);
            RETURN error_handling_ext(i_lang,
                                      'GET_DELIVERY_GRAPH_LINES',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      NULL,
                                      o_error);
    END get_delivery_graph_lines;

    /********************************************************************************************
    * Checks if the pop up message related to the creation of the child episode should appear
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_pat_pregnancy              patient pregnancy ID    
    * @param i_epis_documentation         epis documentation id   
    * @param i_child_number               Child number
    * @param i_child_status               child status: 'A' - alive; 'D' - dead
    * @param o_flg_msg                    indicates if the confirmation message will appear or not: Y - yes; N - No   
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Jos?Silva
    * @version                            1.0   
    * @since                              15-04-2008
    **********************************************************************************************/

    FUNCTION chk_child_epis_creation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_child_number       IN epis_doc_delivery.child_number%TYPE,
        i_child_status       IN epis_doc_delivery.flg_child_status%TYPE,
        o_flg_msg            OUT VARCHAR2,
        o_flg_type           OUT VARCHAR2,
        o_title              OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_config_child CONSTANT sys_config.id_sys_config%TYPE := 'CREATE_CHILD_EPISODE';
        l_epis_documentation epis_documentation.id_epis_documentation%TYPE;
    
        l_exception          EXCEPTION;
        l_error              t_error_out;
        l_external_sys_exist sys_config.value%TYPE := pk_sysconfig.get_config('EXTERNAL_SYSTEM_EXIST', i_prof);
        l_id_ext_sys         sys_config.value%TYPE := pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof);
        l_id_adt_ext_sys     sys_config.value%TYPE := pk_sysconfig.get_config('ADT_EXTERNAL_SYS_IDENTIFIER', i_prof);
        l_code_msg           sys_message.code_message%TYPE;
        l_config_prenatal    sys_config.value%TYPE := pk_sysconfig.get_config('NEWBORN_CHECK_PRENATAL', i_prof);
    BEGIN
    
        g_error := 'CHECK CHILD EPISODE INTEGRITY';
        IF NOT exists_child_episode(i_lang,
                                    i_prof,
                                    i_pat_pregnancy,
                                    i_child_number,
                                    i_epis_documentation,
                                    l_epis_documentation,
                                    l_error)
        THEN
            RAISE l_exception;
        END IF;
        -- THE EXTERNAL SYSTEM IS OUR ADT
        IF (l_external_sys_exist = pk_alert_constant.g_yes AND l_id_ext_sys = l_id_adt_ext_sys)
           OR l_external_sys_exist = pk_alert_constant.g_no
        THEN
            o_flg_type := pk_episode.g_flg_def;
            o_title    := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'WOMAN_HEALTH_M033');
            l_code_msg := 'WOMAN_HEALTH_T178';
        ELSE
            o_flg_type := pk_episode.g_flg_temp;
            o_title    := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'WOMAN_HEALTH_M003');
            l_code_msg := 'WOMAN_HEALTH_T088';
        END IF;
    
        g_error := 'CHECK CHILD STATUS';
        IF i_child_status = g_child_status_alive
           AND pk_sysconfig.get_config(l_config_child, i_prof) = g_yes
           AND l_epis_documentation IS NULL
        THEN
            o_flg_msg := g_yes;
            o_msg     := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => l_code_msg);
        ELSE
            o_flg_msg := g_no;
        END IF;
        IF l_config_prenatal = pk_alert_constant.g_yes
        THEN
            o_msg := o_msg || chr(10) || chr(10) ||
                     pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'WOMAN_HEALTH_M037');
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN error_handling_ext(i_lang,
                                      'CHK_CHILD_EPIS_CREATION',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      NULL,
                                      o_error);
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang,
                                      'CHK_CHILD_EPIS_CREATION',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      NULL,
                                      o_error);
    END chk_child_epis_creation;

    FUNCTION check_obstetric_index
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_doc_area            IN doc_area.id_doc_area%TYPE,
        i_doc_template        IN doc_template.id_doc_template%TYPE,
        i_epis_documentation  IN epis_documentation.id_epis_documentation%TYPE,
        i_validate            IN VARCHAR2,
        i_id_documentation    IN table_number,
        i_id_doc_element      IN table_number,
        i_id_doc_element_crit IN table_number,
        i_value               IN table_varchar,
        o_show_msg            OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_msg_warning         OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_age                patient.age%TYPE;
        l_msg                VARCHAR2(32767);
        l_msg_warning        VARCHAR2(32767);
        l_internal_name      doc_element.internal_name%TYPE;
        l_pregnancy_number   NUMBER;
        l_born_alive         NUMBER;
        l_born_death         NUMBER;
        l_survivor           NUMBER;
        l_previous_condition NUMBER;
        l_previous_alive     NUMBER;
        l_born_order         NUMBER;
        l_previous_born_date VARCHAR2(200 CHAR);
        l_show_msg           VARCHAR2(1 CHAR);
        l_born_alive_si      VARCHAR2(2 CHAR);
        l_born_death_si      VARCHAR2(2 CHAR);
    
        l_type_popup  VARCHAR2(1 CHAR);
        l_title_popup VARCHAR2(200 CHAR);
        l_msg_popup   VARCHAR2(100 CHAR);
        l_exception   EXCEPTION;
        --  l_num
    BEGIN
        l_age := pk_patient.get_pat_age(i_lang, NULL, NULL, NULL, 'YEARS', i_patient);
        l_msg := pk_message.get_message(i_lang, 'COMMON_M080');
        FOR i IN i_id_doc_element.first .. i_id_doc_element.last
        LOOP
            SELECT internal_name
              INTO l_internal_name
              FROM doc_element d
             WHERE d.id_doc_element = i_id_doc_element(i);
        
            IF l_internal_name = g_int_name_pregn_num
            THEN
                l_pregnancy_number := i_value(i);
            ELSIF l_internal_name = g_int_name_born_alive
            THEN
                l_born_alive := i_value(i);
            ELSIF l_internal_name = g_int_name_born_death
            THEN
                l_born_death := i_value(i);
            ELSIF l_internal_name = g_int_name_survivor
            THEN
                l_survivor := i_value(i);
            ELSIF l_internal_name = g_int_name_prev_cond_viv
            THEN
                l_previous_condition := 1;
            ELSIF l_internal_name = g_int_name_prev_cond_mue
            THEN
                l_previous_condition := 2;
            ELSIF l_internal_name = g_int_name_prev_cond_no
            THEN
                l_previous_condition := 3;
            ELSIF l_internal_name = g_int_name_prev_cond_ne
            THEN
                l_previous_condition := 8;
            ELSIF l_internal_name = g_int_name_prev_cond_si
            THEN
                l_previous_condition := 9;
            ELSIF l_internal_name = g_int_name_born_alive_si
            THEN
                l_born_alive_si := pk_alert_constant.g_si;
            ELSIF l_internal_name = g_int_name_born_death_si
            THEN
                l_born_death_si := pk_alert_constant.g_si;
            END IF;
        END LOOP;
        -- rule 1 15 years, she can only be allowed to have at most 9 pregnancie
        IF l_pregnancy_number > 9
           AND l_age < 15
        THEN
            l_msg      := l_msg || chr(10) || pk_message.get_message(i_lang, 'WOMAN_HEALTH_M015');
            l_show_msg := pk_alert_constant.g_yes;
        END IF;
        -- rule 2 
        IF l_survivor > l_born_alive
        THEN
            l_msg      := l_msg || chr(10) || pk_message.get_message(i_lang, 'WOMAN_HEALTH_M016');
            l_show_msg := pk_alert_constant.g_yes;
        END IF;
        --rule 3
        IF l_pregnancy_number = 1
           AND (l_born_death = 0 OR l_born_death IS NULL)
           AND (l_born_alive IS NULL OR l_born_alive = 0)
        THEN
            l_msg      := l_msg || chr(10) || pk_message.get_message(i_lang, 'WOMAN_HEALTH_M017');
            l_show_msg := pk_alert_constant.g_yes;
        END IF;
        -- rule 4 
        IF l_pregnancy_number = 1
           AND l_previous_condition <> 3
        THEN
            l_msg      := l_msg || chr(10) || pk_message.get_message(i_lang, 'WOMAN_HEALTH_M018');
            l_show_msg := pk_alert_constant.g_yes;
        END IF;
        --RULE 5 
        IF (nvl(l_born_death, 0) + nvl(l_born_alive, 0)) > 25
           AND (l_born_alive_si IS NOT NULL AND l_born_death_si IS NOT NULL)
        THEN
            l_msg      := l_msg || chr(10) || pk_message.get_message(i_lang, 'WOMAN_HEALTH_M021');
            l_show_msg := pk_alert_constant.g_yes;
        END IF;
        IF i_validate = pk_alert_constant.g_yes
        THEN
            IF NOT pk_pregnancy.get_pregnancy_popup_limits(i_lang        => i_lang,
                                                           i_prof        => i_prof,
                                                           i_patient     => i_patient,
                                                           i_value       => l_pregnancy_number,
                                                           o_type_popup  => l_type_popup,
                                                           o_title_popup => l_title_popup,
                                                           o_msg_popup   => l_msg_popup,
                                                           o_error       => o_error)
            THEN
                RAISE l_exception;
            END IF;
            IF l_type_popup IS NOT NULL
               AND i_validate = pk_alert_constant.g_yes
            THEN
                l_msg_warning := l_msg_warning || chr(10) || l_msg_popup;
                l_show_msg    := pk_alert_constant.g_yes;
            END IF;
            IF nvl(l_born_death, 0) BETWEEN 10 AND 25
            THEN
                l_msg_warning := l_msg_warning || chr(10) ||
                                 REPLACE(pk_message.get_message(i_lang, 'WOMAN_HEALTH_M030'), '%1', l_born_death);
                l_show_msg    := pk_alert_constant.g_yes;
            END IF;
            IF nvl(l_born_alive, 0) BETWEEN 10 AND 25
            THEN
                l_msg_warning := l_msg_warning || chr(10) ||
                                 REPLACE(pk_message.get_message(i_lang, 'WOMAN_HEALTH_M031'), '%1', l_born_alive);
                l_show_msg    := pk_alert_constant.g_yes;
            END IF;
            IF nvl(l_survivor, 0) BETWEEN 10 AND 25
            THEN
                l_msg_warning := l_msg_warning || chr(10) ||
                                 REPLACE(pk_message.get_message(i_lang, 'WOMAN_HEALTH_M032'), '%1', l_survivor);
                l_show_msg    := pk_alert_constant.g_yes;
            END IF;
        END IF;
        o_show_msg    := l_show_msg;
        o_msg_warning := l_msg_warning;
        o_msg         := l_msg;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang,
                                      'CHECK_OBSTETRIC_INDEX',
                                      '',
                                      'WOMAN_HEALTH_M004',
                                      l_msg,
                                      TRUE,
                                      'D',
                                      NULL,
                                      o_error);
            RETURN FALSE;
    END check_obstetric_index;

    FUNCTION check_prenatal
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_doc_area      IN doc_area.id_doc_area%TYPE,
        o_show_msg      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count    NUMBER;
        l_msg      VARCHAR2(32767);
        l_show_msg VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
    BEGIN
        SELECT COUNT(1)
          INTO l_count
          FROM epis_documentation ed
          JOIN epis_doc_delivery edd
            ON ed.id_epis_documentation = edd.id_epis_documentation
         WHERE edd.id_pat_pregnancy = i_pat_pregnancy
           AND ed.flg_status = 'A'
           AND ed.id_doc_area = i_doc_area;
    
        IF l_count = 0
        THEN
            l_msg      := l_msg || chr(10) || pk_message.get_message(i_lang, 'WOMAN_HEALTH_M036');
            l_show_msg := pk_alert_constant.g_yes;
        END IF;
        o_show_msg := l_show_msg;
        o_msg      := l_msg;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang,
                                      'CHECK_PRENATAL',
                                      '',
                                      'WOMAN_HEALTH_M004',
                                      l_msg,
                                      TRUE,
                                      'D',
                                      NULL,
                                      o_error);
            RETURN FALSE;
    END check_prenatal;

    PROCEDURE get_fetus_limits
    (
        i_weeks      IN NUMBER,
        i_gender     IN VARCHAR2,
        o_min_height OUT NUMBER,
        o_max_height OUT NUMBER,
        o_min_weight OUT NUMBER,
        o_max_weight OUT NUMBER
    ) IS
    
    BEGIN
        SELECT pfl.min_height, pfl.max_height, pfl.min_weight, pfl.max_weight
          INTO o_min_height, o_max_height, o_min_weight, o_max_weight
          FROM pregnancy_fetus_limits pfl
         WHERE pfl.gest_weeks = i_weeks
           AND gender = i_gender;
        NULL;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_fetus_limits;

    FUNCTION check_newborn
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_doc_area            IN doc_area.id_doc_area%TYPE,
        i_doc_template        IN doc_template.id_doc_template%TYPE,
        i_epis_documentation  IN epis_documentation.id_epis_documentation%TYPE,
        i_id_documentation    IN table_number,
        i_id_doc_element      IN table_number,
        i_id_doc_element_crit IN table_number,
        i_value               IN table_varchar,
        i_pat_pregnancy       IN NUMBER,
        i_child_number        IN NUMBER,
        i_validate            IN VARCHAR2 DEFAULT 'N',
        o_show_msg            OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_msg_warning         OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_msg           VARCHAR2(32767);
        l_msg_warning   VARCHAR2(32767);
        l_internal_name doc_element.internal_name%TYPE;
        l_born_alive    NUMBER;
        l_born_alive_si VARCHAR2(200 CHAR);
        l_born_death    NUMBER;
        l_born_death_si VARCHAR2(200 CHAR);
        l_order_nasc    NUMBER;
        l_show_msg      VARCHAR2(1 CHAR);
        l_n_children    pat_pregnancy.n_children%TYPE;
        l_total_child   NUMBER;
        l_atention      VARCHAR2(200 CHAR);
        l_weight        NUMBER;
        l_height        NUMBER;
        l_weight_si     VARCHAR2(2 CHAR);
        l_height_si     VARCHAR2(2 CHAR);
        l_weeks         NUMBER;
        l_min_height    NUMBER;
        l_max_height    NUMBER;
        l_min_weight    NUMBER;
        l_max_weight    NUMBER;
        l_gender        VARCHAR2(1 CHAR);
        l_gender_si     VARCHAR2(2 CHAR);
        l_desc_proc     VARCHAR2(200 CHAR);
    BEGIN
        l_msg := pk_message.get_message(i_lang, 'COMMON_M080');
    
        FOR i IN i_id_doc_element.first .. i_id_doc_element.last
        LOOP
            SELECT internal_name
              INTO l_internal_name
              FROM doc_element d
             WHERE d.id_doc_element = i_id_doc_element(i);
        
            IF l_internal_name = g_int_name_order_nasc
            THEN
                l_order_nasc := i_value(i);
            ELSIF l_internal_name = g_int_name_order_nasc_si
            THEN
                l_order_nasc := -1;
            ELSIF l_internal_name = g_int_name_atention
            THEN
                l_atention := i_value(i);
            ELSIF l_internal_name = g_int_name_weight
            THEN
                l_weight := substr(i_value(i), 1, instr(i_value(i), '|') - 1);
            ELSIF l_internal_name = g_int_name_height
            THEN
                l_height := substr(i_value(i), 1, instr(i_value(i), '|') - 1);
            ELSIF l_internal_name = g_int_name_weight_si
            THEN
                l_weight_si := pk_alert_constant.g_si;
            ELSIF l_internal_name = g_int_name_height
            THEN
                l_height_si := pk_alert_constant.g_si;
            ELSIF l_internal_name = g_int_name_gender_m
            THEN
                l_gender := pk_patient.g_pat_gender_male;
            ELSIF l_internal_name = g_int_name_gender_f
            THEN
                l_gender := pk_patient.g_pat_gender_female;
            ELSIF l_internal_name = g_int_proc_desc
            THEN
                l_desc_proc := i_value(i);
            END IF;
        
        END LOOP;
    
        BEGIN
            SELECT pk_pregnancy_api.get_pregnancy_weeks(i_prof, pp.dt_init_pregnancy, NULL, NULL)
              INTO l_weeks
              FROM pat_pregnancy pp
             WHERE pp.id_pat_pregnancy = i_pat_pregnancy;
        EXCEPTION
            WHEN OTHERS THEN
                l_weeks := NULL;
        END;
    
        --        IF i_flg_type IS NULL         THEN
        -- rule 1 
        IF l_order_nasc <> -1
        THEN
            BEGIN
                SELECT n_children
                  INTO l_n_children
                  FROM pat_pregnancy pp
                 WHERE pp.id_pat_pregnancy = i_pat_pregnancy;
            EXCEPTION
                WHEN OTHERS THEN
                    l_n_children := 0;
            END;
            l_born_alive_si := pk_delivery.get_delivery_value(i_lang             => i_lang,
                                                              i_prof             => NULL,
                                                              i_patient          => i_patient,
                                                              i_pat_pregnancy    => NULL,
                                                              i_child_number     => NULL,
                                                              i_doc_area         => pk_pregnancy_core.g_doc_area_obs_idx_tmpl,
                                                              i_doc_template     => NULL,
                                                              i_doc_component    => NULL,
                                                              i_doc_element      => NULL,
                                                              i_element_int_name => g_int_name_born_alive_si);
            l_born_death_si := pk_delivery.get_delivery_value(i_lang             => i_lang,
                                                              i_prof             => NULL,
                                                              i_patient          => i_patient,
                                                              i_pat_pregnancy    => NULL,
                                                              i_child_number     => NULL,
                                                              i_doc_area         => pk_pregnancy_core.g_doc_area_obs_idx_tmpl,
                                                              i_doc_template     => NULL,
                                                              i_doc_component    => NULL,
                                                              i_doc_element      => NULL,
                                                              i_element_int_name => g_int_name_born_death_si);
            IF l_born_alive_si IS NOT NULL
            THEN
                l_born_alive_si := pk_alert_constant.g_si;
            ELSE
            
                l_born_alive := pk_delivery.get_delivery_value(i_lang             => i_lang,
                                                               i_prof             => NULL,
                                                               i_patient          => i_patient,
                                                               i_pat_pregnancy    => NULL,
                                                               i_child_number     => NULL,
                                                               i_doc_area         => pk_pregnancy_core.g_doc_area_obs_idx_tmpl,
                                                               i_doc_template     => NULL,
                                                               i_doc_component    => NULL,
                                                               i_doc_element      => NULL,
                                                               i_element_int_name => g_int_name_born_alive);
            
                l_born_alive_si := pk_alert_constant.g_no;
            END IF;
            IF l_born_death_si IS NOT NULL
            THEN
                l_born_death_si := pk_alert_constant.g_si;
            ELSE
                l_born_death    := pk_delivery.get_delivery_value(i_lang             => i_lang,
                                                                  i_prof             => NULL,
                                                                  i_patient          => i_patient,
                                                                  i_pat_pregnancy    => NULL,
                                                                  i_child_number     => NULL,
                                                                  i_doc_area         => pk_pregnancy_core.g_doc_area_obs_idx_tmpl,
                                                                  i_doc_template     => NULL,
                                                                  i_doc_component    => NULL,
                                                                  i_doc_element      => NULL,
                                                                  i_element_int_name => g_int_name_born_death);
                l_born_death_si := pk_alert_constant.g_no;
            END IF;
        
            IF l_born_death_si <> pk_alert_constant.g_si
               AND l_born_alive_si <> pk_alert_constant.g_si
            THEN
                l_total_child := nvl(l_born_alive, 0) + nvl(l_born_death, 0);
                IF l_n_children > 1
                THEN
                    IF i_child_number < l_n_children
                       AND ((l_total_child - i_child_number) <> nvl(l_order_nasc, 0) AND l_order_nasc <> -1)
                       AND l_total_child <> 0
                    THEN
                        l_msg      := l_msg || chr(10) || pk_message.get_message(i_lang, 'WOMAN_HEALTH_M019');
                        l_show_msg := pk_alert_constant.g_yes;
                    ELSIF i_child_number = l_n_children
                          AND l_total_child <> nvl(l_order_nasc, 0)
                          AND l_order_nasc <> -1
                          AND l_total_child <> 0
                    THEN
                        l_msg      := l_msg || chr(10) || pk_message.get_message(i_lang, 'WOMAN_HEALTH_M019');
                        l_show_msg := pk_alert_constant.g_yes;
                    END IF;
                ELSE
                    IF l_total_child <> nvl(l_order_nasc, 0)
                       AND l_order_nasc <> -1
                       AND l_total_child <> 0
                    THEN
                        l_msg      := l_msg || chr(10) || pk_message.get_message(i_lang, 'WOMAN_HEALTH_M019');
                        l_show_msg := pk_alert_constant.g_yes;
                    END IF;
                END IF;
            END IF;
        END IF;
        --rule 2
        IF l_atention IS NOT NULL
           AND length(l_atention) > 25
        THEN
            l_msg      := l_msg || chr(10) || pk_message.get_message(i_lang, 'WOMAN_HEALTH_M020');
            l_show_msg := pk_alert_constant.g_yes;
        END IF;
    
        IF l_desc_proc IS NOT NULL
           AND length(l_desc_proc) > 25
        THEN
            l_msg      := l_msg || chr(10) || pk_message.get_message(i_lang, 'WOMAN_HEALTH_M035');
            l_show_msg := pk_alert_constant.g_yes;
        END IF;
        -- rule 3 weigth 
        /*    IF l_weight_si IS NULL
          THEN
              IF l_weeks >= 22
                 AND (l_weight < 501 OR l_weight > 7000)
              THEN
                  l_msg      := l_msg || chr(10) || pk_message.get_message(i_lang, 'WOMAN_HEALTH_M022');
                  l_show_msg := pk_alert_constant.g_yes;
           --   ELSIF l_weeks < 22
        --            AND (l_weight < 1 OR l_weight > 500)
              THEN
                  l_msg      := l_msg || chr(10) || pk_message.get_message(i_lang, 'WOMAN_HEALTH_M023');
                  l_show_msg := pk_alert_constant.g_yes;
              END IF;
          END IF;*/
        -- newborn in pregnancy less than 13
    
        IF l_weeks < 13
        THEN
            l_msg      := l_msg || chr(10) || pk_message.get_message(i_lang, 'WOMAN_HEALTH_M028');
            l_show_msg := pk_alert_constant.g_yes;
        END IF;
        IF i_validate = pk_alert_constant.g_yes
        THEN
            IF l_weeks BETWEEN 13 AND 17
               OR l_weeks BETWEEN 43 AND 45
            THEN
                l_msg_warning := l_msg_warning || chr(10) ||
                                 REPLACE(pk_message.get_message(i_lang, 'WOMAN_HEALTH_M029'), '%1', l_weeks);
                l_show_msg    := pk_alert_constant.g_yes;
            END IF;
            -- rule 4 heigth 
            IF l_height_si IS NULL
            THEN
                IF (l_weeks BETWEEN 13 AND 17 AND ((l_height BETWEEN 10 AND 30) OR (l_height BETWEEN 60 AND 66)))
                   OR (l_weeks BETWEEN 42 AND 45 AND ((l_height BETWEEN 10 AND 30) OR (l_height BETWEEN 61 AND 65)))
                THEN
                    l_msg_warning := l_msg_warning || chr(10) ||
                                     REPLACE(pk_message.get_message(i_lang, 'WOMAN_HEALTH_M025'), '%1', l_height);
                    l_show_msg    := pk_alert_constant.g_yes;
                END IF;
            END IF;
        
            IF l_weight_si IS NULL
            THEN
                IF (l_weeks BETWEEN 13 AND 17 AND (l_weight BETWEEN 22 AND 185) OR
                   ((l_weeks BETWEEN 42 AND 45) AND l_weight BETWEEN 4633 AND 7000))
                THEN
                    l_msg_warning := l_msg_warning || chr(10) ||
                                     REPLACE(pk_message.get_message(i_lang, 'WOMAN_HEALTH_M034'), '%1', l_weight);
                    l_show_msg    := pk_alert_constant.g_yes;
                END IF;
            END IF;
        
            IF l_weeks BETWEEN 18 AND 41
               AND l_gender IN (pk_patient.g_pat_gender_male, pk_patient.g_pat_gender_female)
            THEN
                get_fetus_limits(i_weeks      => l_weeks,
                                 i_gender     => l_gender,
                                 o_min_height => l_min_height,
                                 o_max_height => l_max_height,
                                 o_min_weight => l_min_weight,
                                 o_max_weight => l_max_weight);
                -- RULE 5 weigth in range
                IF l_weight_si IS NULL
                THEN
                    IF l_weight NOT BETWEEN l_min_weight AND l_max_weight
                    THEN
                        l_msg_warning := l_msg_warning || chr(10) ||
                                         REPLACE(pk_message.get_message(i_lang, 'WOMAN_HEALTH_M027'), '%1', l_weeks);
                        l_msg_warning := REPLACE(l_msg_warning, '%2', l_min_weight);
                        l_msg_warning := REPLACE(l_msg_warning, '%3', l_max_weight);
                        l_show_msg    := pk_alert_constant.g_yes;
                    
                    END IF;
                END IF;
                -- RULE 5 weigth in range
                IF l_height_si IS NULL
                THEN
                    IF l_height NOT BETWEEN l_min_height AND l_max_height
                    THEN
                        l_msg_warning := l_msg_warning || chr(10) ||
                                         REPLACE(pk_message.get_message(i_lang, 'WOMAN_HEALTH_M026'), '%1', l_weeks);
                        l_msg_warning := REPLACE(l_msg_warning, '%2', l_min_height);
                        l_msg_warning := REPLACE(l_msg_warning, '%3', l_max_height);
                        l_show_msg    := pk_alert_constant.g_yes;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        --    END IF;
        o_show_msg    := l_show_msg;
        o_msg         := l_msg;
        o_msg_warning := l_msg_warning;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang,
                                      'CHECK_NEWBORN',
                                      '',
                                      'WOMAN_HEALTH_M004',
                                      l_msg,
                                      TRUE,
                                      'U',
                                      NULL,
                                      o_error);
            RETURN FALSE;
    END check_newborn;

    FUNCTION check_pregnancy_initial
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_doc_area            IN doc_area.id_doc_area%TYPE,
        i_doc_template        IN doc_template.id_doc_template%TYPE,
        i_epis_documentation  IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type            IN VARCHAR2,
        i_id_documentation    IN table_number,
        i_id_doc_element      IN table_number,
        i_id_doc_element_crit IN table_number,
        i_value               IN table_varchar,
        o_show_msg            OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_age            patient.age%TYPE;
        l_msg            VARCHAR2(32767);
        l_internal_name  doc_element.internal_name%TYPE;
        l_show_msg       VARCHAR2(1 CHAR);
        l_folio          NUMBER;
        l_mother_death   VARCHAR2(1 CHAR);
        l_code_msg_folio VARCHAR2(0100 CHAR) := 'WOMAN_HEALTH_M024';
        l_folio_si       VARCHAR2(2 CHAR) := pk_alert_constant.g_no;
        --  l_num
    BEGIN
        l_msg := pk_message.get_message(i_lang, 'COMMON_M080');
    
        FOR i IN i_id_doc_element.first .. i_id_doc_element.last
        LOOP
            SELECT internal_name
              INTO l_internal_name
              FROM doc_element d
             WHERE d.id_doc_element = i_id_doc_element(i);
        
            IF l_internal_name = g_int_name_folio
            THEN
                l_folio := i_value(i);
            ELSIF l_internal_name = g_int_mother_death
            THEN
                l_mother_death := pk_alert_constant.g_yes;
            ELSIF l_internal_name = g_int_name_folio_si
            THEN
                l_folio_si := pk_alert_constant.g_si;
            END IF;
        END LOOP;
        -- rule 1 FOLIO MUST HAVE 9 characters
        IF l_mother_death = pk_alert_constant.g_yes
           AND length(l_folio) != 9
           AND l_folio_si <> pk_alert_constant.g_si
        THEN
            l_msg      := l_msg || chr(10) || pk_message.get_message(i_lang, l_code_msg_folio);
            l_show_msg := pk_alert_constant.g_yes;
        END IF;
        o_show_msg := l_show_msg;
        o_msg      := l_msg;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang,
                                      'CHECK_PREGNANCY_INITIAL',
                                      '',
                                      'WOMAN_HEALTH_M004',
                                      l_msg,
                                      TRUE,
                                      'D',
                                      NULL,
                                      o_error);
            RETURN FALSE;
    END check_pregnancy_initial;
    /********************************************************************************************
    * Sets documentation values and partogram registries
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_prof_cat_type              professional category
    * @param i_doc_area                   doc_area id
    * @param i_doc_template               doc_template id
    * @param i_epis_documentation         epis documentation id
    * @param i_flg_type                   A Agree, E edit, N - new 
    * @param i_id_documentation           array with id documentation,
    * @param i_id_doc_element             array with doc elements
    * @param i_id_doc_element_crit        array with doc elements crit
    * @param i_value                      array with values,
    * @param i_notes                      note
    * @param i_id_doc_element_qualif      array with doc elements qualif  
    * @param i_epis_context               episode context id (Ex: id_interv_presc_det,...)
    * @param i_pat_pregnancy              patient pregnancy ID
    * @param i_doc_element_ext            doc_element IDs containing external info
    * @param i_values_ext                 saved doc_element values
    * @param i_child_number               child number associated to saved documentation          
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Jos?Silva
    * @version                            1.0   
    * @since                              24-10-2007
    *
    * @author                             Jos?Silva
    * @version                            2.0    
    * @since                              16-04-2008     
    **********************************************************************************************/

    FUNCTION set_epis_doc_delivery
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation_det.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_pat_pregnancy         IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_doc_element_ext       IN table_number,
        i_values_ext            IN table_number,
        i_child_number          IN epis_doc_delivery.child_number%TYPE,
        i_validate              IN VARCHAR2,
        o_flg_msg               OUT VARCHAR2,
        o_show_warning          OUT VARCHAR2,
        o_flg_type              OUT VARCHAR2,
        o_title                 OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_id_department         OUT dep_clin_serv.id_department%TYPE,
        o_id_clinical_service   OUT dep_clin_serv.id_clinical_service%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_documentation epis_documentation.id_epis_documentation%TYPE;
        l_child_status       epis_doc_delivery.flg_child_status%TYPE;
        l_error_epis_doc     EXCEPTION;
        l_msg_epis_doc       sys_message.desc_message%TYPE;
    
        l_exception   EXCEPTION;
        l_error       t_error_out;
        l_warning     EXCEPTION;
        l_title       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'WOMAN_HEALTH_M004');
        l_msg         VARCHAR2(32767);
        l_msg_warning VARCHAR2(32767);
        l_id_patient  patient.id_patient%TYPE;
        l_show_msg    VARCHAR2(1 CHAR);
        l_validation  sys_config.value%TYPE;
    
        k_config_newborn      sys_config.id_sys_config%TYPE := 'NEWBORN_TEMPLATE_VALIDATIONS';
        k_config_prenatal     sys_config.id_sys_config%TYPE := 'NEWBORN_CHECK_PRENATAL';
        l_ret                 BOOLEAN;
        l_id_clinical_service episode.id_clinical_service%TYPE;
        l_validate_prenatal   sys_config.value%TYPE;
        l_id_episode          episode.id_episode%TYPE;
    BEGIN
    
        l_msg_epis_doc      := pk_message.get_message(i_lang, l_title);
        o_show_warning      := pk_alert_constant.g_no;
        l_validation        := pk_sysconfig.get_config(k_config_newborn, i_prof);
        l_validate_prenatal := pk_sysconfig.get_config(k_config_prenatal, i_prof);
        -- Obstetric index with template
        IF i_doc_area = pk_pregnancy_core.g_doc_area_obs_idx_tmpl
           AND l_validation = pk_alert_constant.g_yes
        THEN
            l_id_patient := pk_episode.get_id_patient(i_epis);
            IF NOT check_obstetric_index(i_lang                => i_lang,
                                         i_prof                => i_prof,
                                         i_patient             => l_id_patient,
                                         i_doc_area            => i_doc_area,
                                         i_doc_template        => i_doc_template,
                                         i_epis_documentation  => i_epis_documentation,
                                         i_validate            => i_validate,
                                         i_id_documentation    => i_id_documentation,
                                         i_id_doc_element      => i_id_doc_element,
                                         i_id_doc_element_crit => i_id_doc_element_crit,
                                         i_value               => i_value,
                                         o_show_msg            => l_show_msg,
                                         o_msg                 => l_msg,
                                         o_msg_warning         => l_msg_warning,
                                         o_error               => o_error)
            
            THEN
                RAISE l_exception;
            END IF;
        
            IF l_show_msg = pk_alert_constant.g_yes
            THEN
                RAISE l_warning;
            END IF;
        ELSIF i_doc_area = pk_pregnancy_core.g_doc_area_born
              AND l_validation = pk_alert_constant.g_yes
        THEN
            l_id_patient := pk_episode.get_id_patient(i_epis);
        
            IF l_validate_prenatal = pk_alert_constant.g_yes
            THEN
                IF NOT check_prenatal(i_lang          => i_lang,
                                      i_prof          => i_prof,
                                      i_patient       => l_id_patient,
                                      i_pat_pregnancy => i_pat_pregnancy,
                                      i_doc_area      => 1097,
                                      o_show_msg      => l_show_msg,
                                      o_msg           => l_msg,
                                      o_error         => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                IF l_show_msg = pk_alert_constant.g_yes
                THEN
                    RAISE l_warning;
                END IF;
            END IF;
            IF NOT check_newborn(i_lang                => i_lang,
                                 i_prof                => i_prof,
                                 i_patient             => l_id_patient,
                                 i_doc_area            => i_doc_area,
                                 i_doc_template        => i_doc_template,
                                 i_epis_documentation  => i_epis_documentation,
                                 i_id_documentation    => i_id_documentation,
                                 i_id_doc_element      => i_id_doc_element,
                                 i_id_doc_element_crit => i_id_doc_element_crit,
                                 i_value               => i_value,
                                 i_pat_pregnancy       => i_pat_pregnancy,
                                 i_child_number        => i_child_number,
                                 i_validate            => i_validate,
                                 o_show_msg            => l_show_msg,
                                 o_msg                 => l_msg,
                                 o_msg_warning         => l_msg_warning,
                                 o_error               => o_error)
            
            THEN
                RAISE l_exception;
            END IF;
            IF l_show_msg = pk_alert_constant.g_yes
            THEN
                RAISE l_warning;
            END IF;
        ELSIF i_doc_area = pk_pregnancy_core.g_doc_area_preg_data
              AND l_validation = pk_alert_constant.g_yes
        THEN
        
            IF NOT check_pregnancy_initial(i_lang                => i_lang,
                                           i_prof                => i_prof,
                                           i_patient             => l_id_patient,
                                           i_doc_area            => i_doc_area,
                                           i_doc_template        => i_doc_template,
                                           i_epis_documentation  => i_epis_documentation,
                                           i_flg_type            => i_flg_type,
                                           i_id_documentation    => i_id_documentation,
                                           i_id_doc_element      => i_id_doc_element,
                                           i_id_doc_element_crit => i_id_doc_element_crit,
                                           i_value               => i_value,
                                           o_show_msg            => l_show_msg,
                                           o_msg                 => l_msg,
                                           o_error               => o_error)
            
            THEN
                RAISE l_exception;
            
            END IF;
            IF l_show_msg = pk_alert_constant.g_yes
            THEN
                RAISE l_warning;
            END IF;
        END IF;
        IF NOT pk_touch_option.set_epis_document_internal(i_lang                  => i_lang,
                                                          i_prof                  => i_prof,
                                                          i_prof_cat_type         => i_prof_cat_type,
                                                          i_epis                  => i_epis,
                                                          i_doc_area              => i_doc_area,
                                                          i_doc_template          => i_doc_template,
                                                          i_epis_documentation    => i_epis_documentation,
                                                          i_flg_type              => i_flg_type,
                                                          i_id_documentation      => i_id_documentation,
                                                          i_id_doc_element        => i_id_doc_element,
                                                          i_id_doc_element_crit   => i_id_doc_element_crit,
                                                          i_value                 => i_value,
                                                          i_notes                 => i_notes,
                                                          i_id_epis_complaint     => NULL,
                                                          i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                          i_epis_context          => i_epis_context,
                                                          o_epis_documentation    => l_epis_documentation,
                                                          o_error                 => l_error)
        THEN
            RAISE l_exception;
        END IF;
        IF i_doc_area <> pk_pregnancy_core.g_doc_area_obs_idx_tmpl
        THEN
            IF NOT set_delivery_epis_doc(i_lang,
                                         i_prof,
                                         i_doc_area,
                                         i_doc_template,
                                         i_pat_pregnancy,
                                         i_doc_element_ext,
                                         i_values_ext,
                                         i_id_doc_element,
                                         i_id_doc_element_crit,
                                         i_value,
                                         l_epis_documentation,
                                         i_child_number,
                                         l_child_status,
                                         o_error)
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSIF l_child_status = g_child_status_err
            THEN
                RAISE l_error_epis_doc;
            END IF;
        
            IF NOT chk_child_epis_creation(i_lang,
                                           i_prof,
                                           i_pat_pregnancy,
                                           i_epis_documentation,
                                           i_child_number,
                                           l_child_status,
                                           o_flg_msg,
                                           o_flg_type,
                                           o_title,
                                           o_msg,
                                           l_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
        IF o_flg_type = pk_episode.g_flg_def
        THEN
            IF i_prof.software = pk_alert_constant.g_soft_oris
            THEN
                SELECT e.id_prev_episode
                  INTO l_id_episode
                  FROM episode e
                 WHERE e.id_episode = i_epis;
            ELSE
                l_id_episode := i_epis;
            END IF;
            IF l_id_episode IS NOT NULL
            THEN
                o_id_department := nvl(pk_episode.get_epis_department(i_lang    => i_lang,
                                                                      i_prof    => i_prof,
                                                                      i_episode => l_id_episode),
                                       -1);
                IF NOT pk_episode.get_epis_clin_serv(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_episode   => l_id_episode,
                                                     o_clin_serv => l_id_clinical_service,
                                                     o_error     => l_error)
                THEN
                    l_id_clinical_service := -1;
                END IF;
                o_id_clinical_service := nvl(l_id_clinical_service, -1);
            ELSE
                o_id_department       := -1;
                o_id_clinical_service := -1;
            END IF;
        END IF;
    
        o_epis_documentation := l_epis_documentation;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_error_epis_doc THEN
            RETURN error_handling_ext(i_lang,
                                      'SET_EPIS_DOC_DELIVERY',
                                      '',
                                      'WOMAN_HEALTH_M004',
                                      l_msg_epis_doc,
                                      TRUE,
                                      'D',
                                      NULL,
                                      o_error);
        WHEN l_exception THEN
            RETURN error_handling_ext(i_lang,
                                      'SET_EPIS_DOC_DELIVERY',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      NULL,
                                      o_error);
        WHEN l_warning THEN
            IF l_msg_warning IS NOT NULL
               AND i_validate = pk_alert_constant.g_yes
            THEN
            
                l_ret := error_handling_ext(i_lang,
                                            'SET_EPIS_DOC_DELIVERY',
                                            '',
                                            NULL,
                                            l_msg_warning,
                                            TRUE,
                                            'D',
                                            NULL,
                                            o_error);
            
                o_show_warning := pk_alert_constant.g_yes;
                RETURN TRUE;
            ELSE
            
                RETURN error_handling_ext(i_lang, 'SET_EPIS_DOC_DELIVERY', '', NULL, l_msg, TRUE, 'U', NULL, o_error);
            END IF;
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang,
                                      'SET_EPIS_DOC_DELIVERY',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      NULL,
                                      o_error);
    END set_epis_doc_delivery;

    FUNCTION set_epis_doc_delivery_internal
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation_det.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_pat_pregnancy         IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_doc_element_ext       IN table_number,
        i_values_ext            IN table_number,
        i_child_number          IN epis_doc_delivery.child_number%TYPE,
        i_validate              IN VARCHAR2,
        o_flg_msg               OUT VARCHAR2,
        o_show_warning          OUT VARCHAR2,
        o_flg_type              OUT VARCHAR2,
        o_title                 OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_documentation epis_documentation.id_epis_documentation%TYPE;
        l_child_status       epis_doc_delivery.flg_child_status%TYPE;
        l_error_epis_doc     EXCEPTION;
        l_msg_epis_doc       sys_message.desc_message%TYPE;
    
        l_exception   EXCEPTION;
        l_error       t_error_out;
        l_warning     EXCEPTION;
        l_title       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'WOMAN_HEALTH_M004');
        l_msg         VARCHAR2(32767);
        l_msg_warning VARCHAR2(32767);
        l_id_patient  patient.id_patient%TYPE;
        l_show_msg    VARCHAR2(1 CHAR);
        l_validation  sys_config.value%TYPE;
    
        k_config_newborn sys_config.id_sys_config%TYPE := 'NEWBORN_TEMPLATE_VALIDATIONS';
        l_ret            BOOLEAN;
    
    BEGIN
    
        l_msg_epis_doc := pk_message.get_message(i_lang, l_title);
        o_show_warning := pk_alert_constant.g_no;
        l_validation   := pk_sysconfig.get_config(k_config_newborn, i_prof);
    
        -- Obstetric index with template
        IF i_doc_area = pk_pregnancy_core.g_doc_area_obs_idx_tmpl
           AND l_validation = pk_alert_constant.g_yes
        THEN
            l_id_patient := pk_episode.get_id_patient(i_epis);
            IF NOT check_obstetric_index(i_lang                => i_lang,
                                         i_prof                => i_prof,
                                         i_patient             => l_id_patient,
                                         i_doc_area            => i_doc_area,
                                         i_doc_template        => i_doc_template,
                                         i_epis_documentation  => i_epis_documentation,
                                         i_validate            => i_validate,
                                         i_id_documentation    => i_id_documentation,
                                         i_id_doc_element      => i_id_doc_element,
                                         i_id_doc_element_crit => i_id_doc_element_crit,
                                         i_value               => i_value,
                                         o_show_msg            => l_show_msg,
                                         o_msg                 => l_msg,
                                         o_msg_warning         => l_msg_warning,
                                         o_error               => o_error)
            
            THEN
                RAISE l_exception;
            END IF;
        
            IF l_show_msg = pk_alert_constant.g_yes
            THEN
                RAISE l_warning;
            END IF;
        ELSIF i_doc_area = pk_pregnancy_core.g_doc_area_born
              AND l_validation = pk_alert_constant.g_yes
        THEN
        
            l_id_patient := pk_episode.get_id_patient(i_epis);
            IF NOT check_newborn(i_lang                => i_lang,
                                 i_prof                => i_prof,
                                 i_patient             => l_id_patient,
                                 i_doc_area            => i_doc_area,
                                 i_doc_template        => i_doc_template,
                                 i_epis_documentation  => i_epis_documentation,
                                 i_id_documentation    => i_id_documentation,
                                 i_id_doc_element      => i_id_doc_element,
                                 i_id_doc_element_crit => i_id_doc_element_crit,
                                 i_value               => i_value,
                                 i_pat_pregnancy       => i_pat_pregnancy,
                                 i_child_number        => i_child_number,
                                 i_validate            => i_validate,
                                 o_show_msg            => l_show_msg,
                                 o_msg                 => l_msg,
                                 o_msg_warning         => l_msg_warning,
                                 o_error               => o_error)
            
            THEN
                RAISE l_exception;
            END IF;
            IF l_show_msg = pk_alert_constant.g_yes
            THEN
                RAISE l_warning;
            END IF;
        ELSIF i_doc_area = pk_pregnancy_core.g_doc_area_preg_data
              AND l_validation = pk_alert_constant.g_yes
        THEN
        
            IF NOT check_pregnancy_initial(i_lang                => i_lang,
                                           i_prof                => i_prof,
                                           i_patient             => l_id_patient,
                                           i_doc_area            => i_doc_area,
                                           i_doc_template        => i_doc_template,
                                           i_epis_documentation  => i_epis_documentation,
                                           i_flg_type            => i_flg_type,
                                           i_id_documentation    => i_id_documentation,
                                           i_id_doc_element      => i_id_doc_element,
                                           i_id_doc_element_crit => i_id_doc_element_crit,
                                           i_value               => i_value,
                                           o_show_msg            => l_show_msg,
                                           o_msg                 => l_msg,
                                           o_error               => o_error)
            
            THEN
                RAISE l_exception;
            
            END IF;
            IF l_show_msg = pk_alert_constant.g_yes
            THEN
                RAISE l_warning;
            END IF;
        END IF;
        IF NOT pk_touch_option.set_epis_document_internal(i_lang                  => i_lang,
                                                          i_prof                  => i_prof,
                                                          i_prof_cat_type         => i_prof_cat_type,
                                                          i_epis                  => i_epis,
                                                          i_doc_area              => i_doc_area,
                                                          i_doc_template          => i_doc_template,
                                                          i_epis_documentation    => i_epis_documentation,
                                                          i_flg_type              => i_flg_type,
                                                          i_id_documentation      => i_id_documentation,
                                                          i_id_doc_element        => i_id_doc_element,
                                                          i_id_doc_element_crit   => i_id_doc_element_crit,
                                                          i_value                 => i_value,
                                                          i_notes                 => i_notes,
                                                          i_id_epis_complaint     => NULL,
                                                          i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                          i_epis_context          => i_epis_context,
                                                          o_epis_documentation    => l_epis_documentation,
                                                          o_error                 => l_error)
        THEN
            RAISE l_exception;
        END IF;
        IF i_doc_area <> pk_pregnancy_core.g_doc_area_obs_idx_tmpl
        THEN
            IF NOT set_delivery_epis_doc(i_lang,
                                         i_prof,
                                         i_doc_area,
                                         i_doc_template,
                                         i_pat_pregnancy,
                                         i_doc_element_ext,
                                         i_values_ext,
                                         i_id_doc_element,
                                         i_id_doc_element_crit,
                                         i_value,
                                         l_epis_documentation,
                                         i_child_number,
                                         l_child_status,
                                         o_error)
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSIF l_child_status = g_child_status_err
            THEN
                RAISE l_error_epis_doc;
            END IF;
        
            IF NOT chk_child_epis_creation(i_lang,
                                           i_prof,
                                           i_pat_pregnancy,
                                           i_epis_documentation,
                                           i_child_number,
                                           l_child_status,
                                           o_flg_msg,
                                           o_flg_type,
                                           o_title,
                                           o_msg,
                                           l_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
        o_epis_documentation := l_epis_documentation;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_error_epis_doc THEN
            RETURN error_handling_ext(i_lang,
                                      'SET_EPIS_DOC_DELIVERY',
                                      '',
                                      'WOMAN_HEALTH_M004',
                                      l_msg_epis_doc,
                                      TRUE,
                                      'D',
                                      NULL,
                                      o_error);
        WHEN l_exception THEN
            RETURN error_handling_ext(i_lang,
                                      'SET_EPIS_DOC_DELIVERY',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      NULL,
                                      o_error);
        WHEN l_warning THEN
            IF l_msg_warning IS NOT NULL
               AND i_validate = pk_alert_constant.g_yes
            THEN
            
                l_ret := error_handling_ext(i_lang,
                                            'SET_EPIS_DOC_DELIVERY',
                                            '',
                                            NULL,
                                            l_msg_warning,
                                            TRUE,
                                            'D',
                                            NULL,
                                            o_error);
            
                o_show_warning := pk_alert_constant.g_yes;
                RETURN TRUE;
            ELSE
            
                RETURN error_handling_ext(i_lang, 'SET_EPIS_DOC_DELIVERY', '', NULL, l_msg, TRUE, 'D', NULL, o_error);
            END IF;
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang,
                                      'SET_EPIS_DOC_DELIVERY',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      NULL,
                                      o_error);
    END set_epis_doc_delivery_internal;

    FUNCTION set_child_episode_internal
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_child_number       IN epis_doc_delivery.child_number%TYPE,
        i_patient_child      IN patient.id_patient%TYPE,
        i_child_episode      IN episode.id_episode%TYPE,
        i_commit             IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_fetus_number       epis_doc_delivery.fetus_number%TYPE;
        l_fetus_gender       pat_pregn_fetus.flg_gender%TYPE;
        l_fetus_name         patient.name%TYPE;
        l_fetus_alias        patient.alias%TYPE;
        l_fetus_first_name   patient.first_name%TYPE;
        l_fetus_first_name_m patient.first_name%TYPE;
        l_fetus_middle_name  patient.middle_name%TYPE;
        l_fetus_last_name    patient.last_name%TYPE;
        l_fetus_second_name  patient.second_name%TYPE;
        l_maiden_name        patient.maiden_name%TYPE;
        l_mother_surname     patient.mother_surname_maiden%TYPE;
    
        l_name_number   VARCHAR2(10);
        l_name_mother   patient.name%TYPE;
        l_alias_mother  patient.alias%TYPE;
        l_vip_mother    patient.vip_status%TYPE;
        l_dt_birth_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_val           sys_domain.val%TYPE;
        l_domain_child_name     CONSTANT sys_domain.code_domain%TYPE := 'CHILD_PATIENT_NAME';
        l_val_child_more        CONSTANT sys_domain.val%TYPE := 'M';
        l_val_child_single      CONSTANT sys_domain.val%TYPE := 'S';
        l_id_fam_relationship_m CONSTANT family_relationship.id_family_relationship%TYPE := 3;
        l_id_fam_rel_mother     CONSTANT family_relationship.id_family_relationship%TYPE := 2;
    
        l_id_fam_relationship family_relationship.id_family_relationship%TYPE;
    
        l_error     t_error_out;
        l_exception EXCEPTION;
        l_rowids    table_varchar;
        l_domain_child_name_gender CONSTANT sys_domain.code_domain%TYPE := 'CHILD_PATIENT_NAME.GENDER';
        l_sysconfig_patname_gender CONSTANT sys_config.id_sys_config%TYPE := 'NEWBORN_NAME_BY_GENDER';
        l_sysconfig_twin_name      CONSTANT sys_config.id_sys_config%TYPE := 'NEWBORN_TWIN_NAME_INCLUDE_NUMBER';
        l_val_sysconf_patname_gender sys_config.value%TYPE;
        l_newborn_name               sys_domain.desc_val%TYPE;
        l_twin_name                  sys_domain.desc_val%TYPE;
        l_id_country                 NUMBER(24);
        l_short_code                 VARCHAR2(50 CHAR);
        l_config                     VARCHAR2(200 CHAR);
        l_other_names_1              patient.other_names_1%TYPE;
        l_other_names_2              patient.other_names_2%TYPE;
        l_other_names_3              patient.other_names_3%TYPE;
        l_other_names_4              patient.other_names_4%TYPE;
        l_first_name_arabic          patient.other_names_1%TYPE;
        l_id_mother_nationality      pat_soc_attributes.id_country_nation%TYPE;
    BEGIN
        g_error := 'GET FETUS NUMBER';
        IF NOT get_fetus_number(i_lang, i_prof, i_pat_pregnancy, l_fetus_number, l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'GET BIRTH DATE';
        IF NOT
            get_dt_birth(i_lang, i_prof, i_pat_pregnancy, g_type_dt_birth_e, i_child_number, l_dt_birth_tstz, l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'GET CHILD GENDER';
        SELECT ppf.flg_gender
          INTO l_fetus_gender
          FROM pat_pregn_fetus ppf
         WHERE ppf.id_pat_pregnancy = i_pat_pregnancy
           AND ppf.fetus_number = i_child_number
           AND ppf.flg_status = g_pregn_fetus_a;
    
        g_error := 'GET MOTHER NAME';
        SELECT name, alias, vip_status
          INTO l_name_mother, l_alias_mother, l_vip_mother
          FROM patient
         WHERE id_patient = i_patient;
    
        l_twin_name := pk_sysconfig.get_config(i_prof => i_prof, i_code_cf => l_sysconfig_twin_name);
    
        IF l_twin_name = pk_alert_constant.get_yes
        THEN
            l_name_number := to_char(i_child_number) || ' ';
        END IF;
    
        g_error := 'GET DOMAIN VAL';
        IF i_child_number > 3
        THEN
            l_val := l_val_child_more;
        ELSIF l_fetus_number > 1
        THEN
            l_val := i_child_number;
        ELSE
            l_val         := l_val_child_single;
            l_name_number := NULL;
        END IF;
    
        g_error := 'UPDATE EPIS DOC DELIVERY';
        UPDATE epis_doc_delivery ed
           SET ed.id_child_episode = i_child_episode
         WHERE ed.id_pat_pregnancy = i_pat_pregnancy
           AND ed.id_epis_documentation = i_epis_documentation;
    
        l_val_sysconf_patname_gender := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                i_code_cf => l_sysconfig_patname_gender);
    
        l_twin_name := pk_sysconfig.get_config(i_prof => i_prof, i_code_cf => l_sysconfig_twin_name);
    
        --      l_child_name_mother := pk_sysconfig.get_config(i_prof => i_prof, i_code_cf => l_sysconfig_child_name_mother);
    
        IF l_val_sysconf_patname_gender = pk_alert_constant.g_yes
           AND l_val = l_val_child_single
        THEN
            BEGIN
                SELECT sd.desc_val
                  INTO l_newborn_name
                  FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, l_domain_child_name_gender, NULL)) sd
                
                 WHERE sd.val = l_fetus_gender;
            EXCEPTION
                WHEN OTHERS THEN
                    l_newborn_name := pk_sysdomain.get_domain(l_domain_child_name_gender, l_fetus_gender, i_lang);
            END;
        ELSE
            SELECT sd.desc_val
              INTO l_newborn_name
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, l_domain_child_name, NULL)) sd
             WHERE sd.val = l_val;
            --   l_newborn_name := pk_sysdomain.get_domain(l_domain_child_name, l_val, i_lang);
        END IF;
        g_error := 'GET FETUS NAME';
    
        --   l_fetus_name := l_name_number || l_newborn_name 
    
        g_error := 'GET FETUS ALIAS';
        IF l_alias_mother IS NOT NULL
        THEN
            l_fetus_alias := l_name_number || l_newborn_name || ' ' || l_alias_mother;
        END IF;
    
        IF NOT pk_adt.get_pat_divided_name(i_lang           => i_lang,
                                           i_prof           => i_prof,
                                           i_patient        => i_patient,
                                           o_first_name     => l_fetus_first_name_m,
                                           o_second_name    => l_fetus_second_name,
                                           o_middle_name    => l_fetus_middle_name,
                                           o_last_name      => l_fetus_last_name,
                                           o_maiden_name    => l_maiden_name,
                                           o_mother_surname => l_mother_surname,
                                           o_error          => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        l_config           := pk_sysconfig.get_config(i_prof => i_prof, i_code_cf => 'PATIENT_NAME_PATTERN');
        l_fetus_first_name := l_name_number || l_newborn_name || ' ' || l_fetus_first_name_m;
    
        IF NOT pk_adt.build_name(i_lang        => i_lang,
                                 i_prof        => i_prof,
                                 i_config      => l_config,
                                 i_first_name  => l_fetus_first_name,
                                 i_second_name => l_fetus_second_name,
                                 i_midlle_name => l_fetus_middle_name,
                                 i_last_name   => l_fetus_last_name,
                                 o_pat_name    => l_fetus_name,
                                 o_error       => l_error)
        THEN
            NULL;
        END IF;
    
        IF NOT pk_adt.get_pat_other_names(i_lang          => i_lang,
                                          i_prof          => i_prof,
                                          i_patient       => i_patient,
                                          o_other_names_1 => l_other_names_1,
                                          o_other_names_2 => l_other_names_2,
                                          o_other_names_3 => l_other_names_3,
                                          o_other_names_4 => l_other_names_4)
        THEN
            RAISE l_exception;
        END IF;
    
        IF NOT pk_backoffice.get_name_translation(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_name       => l_fetus_first_name,
                                                  i_type       => 0,
                                                  o_name_trans => l_first_name_arabic,
                                                  o_error      => o_error)
        THEN
            l_first_name_arabic := NULL;
        END IF;
        IF l_first_name_arabic IS NULL
        THEN
            l_first_name_arabic := l_fetus_first_name;
            l_first_name_arabic := l_other_names_1;
        END IF;
    
        g_error := 'UPDATE PATIENT';
        ts_patient.upd(id_patient_in  => i_patient_child,
                       name_in        => l_fetus_name,
                       first_name_in  => l_fetus_first_name,
                       middle_name_in => l_fetus_middle_name,
                       last_name_in   => l_fetus_last_name,
                       gender_in      => l_fetus_gender,
                       dt_birth_in    => trunc(CAST(l_dt_birth_tstz AS DATE)),
                       rows_out       => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PATIENT',
                                      i_rowids     => l_rowids,
                                      o_error      => l_error);
    
        l_id_mother_nationality := pk_adt.get_patient_id_county(i_lang       => i_lang,
                                                                i_prof       => i_prof,
                                                                i_id_patient => i_patient);
        g_error                 := 'UPDATE FETUS INFORMATION ';
        UPDATE patient p
           SET p.alias                 = l_fetus_alias,
               p.vip_status            = l_vip_mother,
               p.dt_birth_tstz         = l_dt_birth_tstz,
               p.flg_type_dt_birth     = pk_patient.g_flg_type_birth_f,
               p.flg_level_dt_birth    = pk_patient.g_flg_level_dt_birth_h,
               p.second_name           = l_fetus_second_name,
               p.maiden_name           = l_maiden_name,
               p.mother_surname_maiden = l_mother_surname,
               p.other_names_1         = l_first_name_arabic,
               p.other_names_2         = l_other_names_2,
               p.other_names_3         = l_other_names_3,
               p.other_names_4         = l_other_names_4
         WHERE p.id_patient = i_patient_child;
    
        l_id_country := pk_backoffice.get_inst_field(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_id_institution => i_prof.institution,
                                                     i_field          => 'ID_COUNTRY');
    
        -- MX - Clues                                             
        l_short_code := pk_adt.get_clues_field(i_id_clues       => NULL,
                                               i_field          => pk_adt.k_institution_short_code,
                                               i_id_institution => i_prof.institution);
    
        IF NOT pk_adt.set_pat_birthplace(i_lang                  => i_lang,
                                         i_prof                  => i_prof,
                                         i_patient               => i_patient_child,
                                         i_id_country            => l_id_country,
                                         i_institution_code      => l_short_code,
                                         i_id_mother_nationality => l_id_mother_nationality,
                                         o_error                 => o_error)
        THEN
            NULL;
        END IF;
    
        g_error               := 'GET FAMILY RELATIONSHIP';
        l_id_fam_relationship := l_id_fam_relationship_m;
    
        g_error := 'UPDATE PAT FAMILY 1';
        IF NOT pk_social.create_pat_family_internal(i_lang                   => i_lang,
                                                    i_id_pat                 => i_patient,
                                                    i_id_new_pat             => i_patient_child,
                                                    i_prof                   => i_prof,
                                                    i_name                   => l_fetus_name,
                                                    i_gender                 => l_fetus_gender,
                                                    i_dt_birth               => NULL,
                                                    i_id_family_relationship => l_id_fam_relationship,
                                                    i_marital_status         => NULL,
                                                    i_scholarship            => NULL,
                                                    i_pension                => NULL,
                                                    i_currency_pension       => NULL,
                                                    i_net_wage               => NULL,
                                                    i_currency_net_wage      => NULL,
                                                    i_unemployment_subsidy   => NULL,
                                                    i_currency_unemp_sub     => NULL,
                                                    i_job                    => NULL,
                                                    i_occupation_desc        => NULL,
                                                    i_prof_cat_type          => pk_prof_utils.get_category(i_lang, i_prof),
                                                    i_epis                   => -1,
                                                    o_error                  => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'UPDATE PAT FAMILY 1';
        IF NOT pk_social.create_pat_family_internal(i_lang                   => i_lang,
                                                    i_id_pat                 => i_patient_child,
                                                    i_id_new_pat             => i_patient,
                                                    i_prof                   => i_prof,
                                                    i_name                   => l_fetus_name,
                                                    i_gender                 => l_fetus_gender,
                                                    i_dt_birth               => NULL,
                                                    i_id_family_relationship => l_id_fam_rel_mother,
                                                    i_marital_status         => NULL,
                                                    i_scholarship            => NULL,
                                                    i_pension                => NULL,
                                                    i_currency_pension       => NULL,
                                                    i_net_wage               => NULL,
                                                    i_currency_net_wage      => NULL,
                                                    i_unemployment_subsidy   => NULL,
                                                    i_currency_unemp_sub     => NULL,
                                                    i_job                    => NULL,
                                                    i_occupation_desc        => NULL,
                                                    i_prof_cat_type          => pk_prof_utils.get_category(i_lang, i_prof),
                                                    i_epis                   => -1,
                                                    o_error                  => l_error)
        THEN
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            RETURN error_handling_ext(i_lang,
                                      'CREATE_CHILD_EPISODE',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      NULL,
                                      o_error);
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang,
                                      'CREATE_CHILD_EPISODE',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      NULL,
                                      o_error);
    END set_child_episode_internal;

    /********************************************************************************************
    * Creates a temporary episode to the newborn child
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_patient                    patient ID (mother)
    * @param i_pat_pregnancy              pregnancy ID
    * @param i_child_number               child number associated with the current documentation
    * @param i_new_patient                patient ID for the born child
    * @param o_episode                    ID of the created episode
    * @param o_patient                    ID of the created patient
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Jos?Silva
    * @version                            1.0   
    * @since                              15-04-2008
    
    * @author                             Jos?Silva
    * @version                            2.0   
    * @since                              20-04-2009
    **********************************************************************************************/
    FUNCTION create_child_episode
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_child_number       IN epis_doc_delivery.child_number%TYPE,
        i_new_patient        IN patient.id_patient%TYPE,
        o_episode            OUT episode.id_episode%TYPE,
        o_patient            OUT patient.id_patient%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_episode  episode.id_episode%TYPE;
        l_id_patient  patient.id_patient%TYPE;
        l_id_schedule schedule.id_schedule%TYPE;
    
        l_software_oris CONSTANT software.id_software%TYPE := pk_sysconfig.get_config('SOFTWARE_ID_ORIS', i_prof);
    
        l_exception      EXCEPTION;
        l_temp_exception EXCEPTION;
        l_error          t_error_out;
        l_rowids         table_varchar;
    
        l_ret         NUMBER;
        l_ora_sqlcode VARCHAR2(200);
        l_ora_sqlerrm VARCHAR2(4000);
        l_err_desc    VARCHAR2(4000);
        l_err_action  VARCHAR2(4000);
    
    BEGIN
    
        l_id_patient := i_new_patient;
    
        IF i_prof.software = l_software_oris
        THEN
            g_error := 'CREATE EPISODE TEMP 1';
            l_ret   := pk_sr_visit.create_all_surgery(i_lang           => i_lang,
                                                      i_id_prof        => i_prof.id,
                                                      i_id_institution => i_prof.institution,
                                                      i_id_software    => i_prof.software,
                                                      i_patient        => l_id_patient,
                                                      o_schedule       => l_id_schedule,
                                                      o_ora_sqlcode    => l_ora_sqlcode,
                                                      o_ora_sqlerrm    => l_ora_sqlerrm,
                                                      o_err_desc       => l_err_desc,
                                                      o_err_action     => l_err_action);
        
        ELSE
            g_error := 'CREATE EPISODE TEMP 2';
            l_ret   := pk_visit.create_episode_temp(i_lang           => i_lang,
                                                    i_id_prof        => i_prof.id,
                                                    i_id_institution => i_prof.institution,
                                                    i_id_software    => i_prof.software,
                                                    i_id_patient     => l_id_patient,
                                                    o_ora_sqlcode    => l_ora_sqlcode,
                                                    o_ora_sqlerrm    => l_ora_sqlerrm,
                                                    o_err_desc       => l_err_desc,
                                                    o_err_action     => l_err_action);
        END IF;
    
        IF l_ret = -1
        THEN
            RAISE l_temp_exception;
        END IF;
    
        l_id_episode := l_ret;
    
        IF NOT set_child_episode_internal(i_lang               => i_lang,
                                          i_prof               => i_prof,
                                          i_patient            => i_patient,
                                          i_pat_pregnancy      => i_pat_pregnancy,
                                          i_epis_documentation => i_epis_documentation,
                                          i_child_number       => i_child_number,
                                          i_patient_child      => i_new_patient,
                                          i_child_episode      => l_id_episode,
                                          i_commit             => pk_alert_constant.g_no,
                                          o_error              => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        o_episode := l_id_episode;
        o_patient := l_id_patient;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_temp_exception THEN
            RETURN error_handling_ext(i_lang,
                                      'CREATE_CHILD_EPISODE',
                                      g_error || ' / ' || l_err_desc,
                                      l_ora_sqlcode,
                                      l_ora_sqlerrm,
                                      TRUE,
                                      'S',
                                      l_err_action,
                                      o_error);
        
        WHEN l_exception THEN
            RETURN error_handling_ext(i_lang,
                                      'CREATE_CHILD_EPISODE',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      NULL,
                                      o_error);
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang,
                                      'CREATE_CHILD_EPISODE',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      NULL,
                                      o_error);
    END create_child_episode;

    /********************************************************************************************
    * Cancel an episode documentation associated with labor and delivery assessment
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_epis_doc            the documentation episode ID to cancelled
    * @param i_notes                  Cancel Notes
    * @param i_test                   Shows the confirmation message (Y / N)
    * @param o_flg_show               Shows the confirmation message (Y / N)
    * @param o_msg_title              Message title, if O_FLG_SHOW = Y
    * @param o_msg_text               Message text, if O_FLG_SHOW = Y
    * @param o_button                 Buttons to show: N - No, R - Read, C - Confirmed                            
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Jos?Silva
    * @version                        1.0   
    * @since                          16/04/2008
    **********************************************************************************************/
    FUNCTION cancel_epis_doc_delivery
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_id_epis_doc   IN epis_documentation.id_epis_documentation%TYPE,
        i_notes         IN VARCHAR2,
        i_test          IN VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg_text      OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_documentation epis_documentation.id_epis_documentation%TYPE;
        l_error_epis_doc     EXCEPTION;
        l_msg_epis_doc       sys_message.desc_message%TYPE;
        l_id_doc_area        doc_area.id_doc_area%TYPE;
        l_child_number       epis_doc_delivery.child_number%TYPE;
    
        l_error_cancel sys_message.desc_message%TYPE;
    
        l_exception EXCEPTION;
        l_error     t_error_out;
    BEGIN
    
        l_msg_epis_doc := pk_message.get_message(i_lang, 'WOMAN_HEALTH_M004');
    
        g_error := 'CHECK CHILD EPISODE INTEGRITY';
        IF i_test = g_yes
        THEN
            IF NOT
                exists_child_episode(i_lang, i_prof, i_pat_pregnancy, NULL, i_id_epis_doc, l_epis_documentation, l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            IF l_epis_documentation IS NOT NULL
            THEN
                RAISE l_error_epis_doc;
            END IF;
        
        END IF;
    
        g_error := 'CALL TO CANCEL_EPIS_DOC_NO_COMMIT';
        IF NOT pk_touch_option.cancel_epis_doc_no_commit(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_id_epis_doc => i_id_epis_doc,
                                                         i_notes       => i_notes,
                                                         i_test        => i_test,
                                                         o_flg_show    => o_flg_show,
                                                         o_msg_title   => o_msg_title,
                                                         o_msg_text    => o_msg_text,
                                                         o_button      => o_button,
                                                         o_error       => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF i_test = g_no
        THEN
        
            g_error := 'GET DOC AREA';
            SELECT ed.id_doc_area, edd.child_number
              INTO l_id_doc_area, l_child_number
              FROM epis_documentation ed, epis_doc_delivery edd
             WHERE ed.id_epis_documentation = i_id_epis_doc
               AND ed.id_epis_documentation = edd.id_epis_documentation;
        
            g_error := 'CANCEL PREGNANCY INFO';
            IF NOT pk_pregnancy_api.set_pat_pregn_delivery(i_lang,
                                                           i_prof,
                                                           i_pat_pregnancy,
                                                           l_id_doc_area,
                                                           l_child_number,
                                                           'C',
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           i_id_epis_doc,
                                                           l_error_cancel,
                                                           o_error)
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        
        END IF;
    
        g_error := 'CHECK ERROR CANCEL';
        IF l_error_cancel IS NOT NULL
        THEN
            RAISE l_exception;
        END IF;
    
        --
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_error_epis_doc THEN
            RETURN error_handling_ext(i_lang,
                                      'CANCEL_EPIS_DOC_DELIVERY',
                                      '',
                                      'WOMAN_HEALTH_M004',
                                      l_msg_epis_doc,
                                      TRUE,
                                      'D',
                                      NULL,
                                      o_error);
        WHEN l_exception THEN
            RETURN error_handling_ext(i_lang,
                                      'CANCEL_EPIS_DOC_DELIVERY',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      NULL,
                                      o_error);
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang,
                                      'CANCEL_EPIS_DOC_DELIVERY',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      NULL,
                                      o_error);
    END cancel_epis_doc_delivery;

    /********************************************************************************************
    * Cancels a column or a single vital sign read in the delivery momitoring
    *
    * @param i_lang                  language id
    * @param i_patient               patient id
    * @param i_prof                  professional, software and institution ids
    * @param i_pat_pregnancy         pregnancy id
    * @param i_vs_read               single vital sign read ID
    * @param i_dt_read               column date of vital sign reads
    *         
    * @return                        true or false on success or error
    *
    * @author                        Jos?Silva
    * @version                       1.0    
    * @since                         27-05-2008
    ********************************************************************************************/
    FUNCTION cancel_delivery_biometric
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_vs_read       IN vital_sign_read.id_vital_sign_read%TYPE,
        i_dt_read       IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_vs_pregnancy IS
            SELECT vp.id_vital_sign_read
              FROM vital_sign_pregnancy vp, vital_sign_read vsr
             WHERE vp.id_pat_pregnancy = i_pat_pregnancy
               AND vp.id_vital_sign_read = vsr.id_vital_sign_read
               AND vsr.dt_vital_sign_read_tstz = pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_read, NULL);
    
        CURSOR c_vs_id IS
            SELECT vp.id_vital_sign_read
              FROM vital_sign_pregnancy vp
             WHERE vp.id_pat_pregnancy = i_pat_pregnancy
               AND (vp.id_vital_sign_read = i_vs_read OR
                   vp.id_vital_sign_read IN
                   (SELECT vr2.id_vital_sign_read
                       FROM vital_sign_read vr2, vital_sign_read vr3, vital_sign_relation v2, vital_sign_relation v3
                      WHERE vr3.id_vital_sign_read = i_vs_read
                        AND vr2.id_vital_sign = v2.id_vital_sign_detail
                        AND vr3.id_vital_sign = v3.id_vital_sign_detail
                        AND v2.relation_domain = g_vs_rel_conc
                        AND v3.relation_domain = g_vs_rel_conc
                        AND vr3.dt_vital_sign_read_tstz = vr2.dt_vital_sign_read_tstz
                        AND v2.id_vital_sign_parent = v3.id_vital_sign_parent));
    
        l_exception EXCEPTION;
        l_error     t_error_out;
    
    BEGIN
    
        IF i_vs_read IS NOT NULL
        THEN
            FOR r_vs_id IN c_vs_id
            LOOP
                g_error := 'CANCEL SINGLE READ';
                IF NOT pk_vital_sign.cancel_biometric_read(i_lang, r_vs_id.id_vital_sign_read, i_prof, l_error)
                THEN
                    RAISE l_exception;
                END IF;
            END LOOP;
        ELSE
        
            FOR r_vs_pregnancy IN c_vs_pregnancy
            LOOP
                g_error := 'CANCEL DATE READ ' || r_vs_pregnancy.id_vital_sign_read;
                IF NOT pk_vital_sign.cancel_biometric_read(i_lang, r_vs_pregnancy.id_vital_sign_read, i_prof, l_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            END LOOP;
        
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN error_handling_ext(i_lang,
                                      'CANCEL_DELIVERY_BIOMETRIC',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      NULL,
                                      o_error);
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang,
                                      'CANCEL_DELIVERY_BIOMETRIC',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      NULL,
                                      o_error);
    END cancel_delivery_biometric;

    /********************************************************************************************
    * Gets the graph scales
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution ids
    * @param o_graph_scales          all scales to display in the graphic
    * @param o_lines                 Static lines   
    * @param o_error                 Error message    
    *         
    * @return                        true or false on success or error
    *
    * @author                        Jos?Silva
    * @version                       1.0    
    * @since                         30-05-2008
    ********************************************************************************************/
    FUNCTION get_delivery_graph_scales
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_graph_scales OUT pk_types.cursor_type,
        o_lines        OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_domain_graph CONSTANT sys_domain.code_domain%TYPE := 'WOMAN_HEALTH.DELIVERY_GRAPH';
        l_id_market market.id_market%TYPE;
    
    BEGIN
    
        g_error := 'GET ID_MARKET';
        SELECT id_market
          INTO l_id_market
          FROM institution i
         WHERE i.id_institution = i_prof.institution;
    
        g_error := 'OPEN CURSOR o_graph_scales';
        OPEN o_graph_scales FOR
            SELECT gs.id_graph_scale,
                   pk_utils.str_token(gs.desc_sc, 1, '|') desc_scale,
                   pk_utils.str_token(gs.desc_sc, 2, '|') desc_measure,
                   gs.rank,
                   CAST(MULTISET (SELECT gsc.value_display
                           FROM graph_scale_cell gsc
                          WHERE gsc.id_graph_scale = gs.id_graph_scale
                          ORDER BY gsc.rank) AS table_varchar) scale_values
              FROM (SELECT gsc.*, pk_translation.get_translation(i_lang, gsc.code_graph_scale) desc_sc
                      FROM graph_scale gsc
                     WHERE gsc.flg_type = g_grapfic_scale_p
                       AND gsc.flg_available = g_available) gs
             WHERE gs.id_graph_scale IN (SELECT id_graph_scale
                                           FROM (SELECT gss.id_graph_scale, gss.id_vital_sign
                                                   FROM graph_scale gss, graph_scale_inst gi
                                                  WHERE gi.id_institution IN (i_prof.institution, 0)
                                                    AND gss.flg_type = g_grapfic_scale_p
                                                    AND gss.id_graph_scale = gi.id_graph_scale
                                                    AND gi.id_market IN (l_id_market, 0)
                                                    AND gss.flg_available = g_available
                                                  ORDER BY gi.id_institution DESC, gi.id_market DESC) g
                                          WHERE nvl(g.id_vital_sign, 0) = nvl(gs.id_vital_sign, 0)
                                            AND rownum = 1)
             ORDER BY gs.rank;
    
        g_error := 'OPEN CURSOR O_LINES';
        OPEN o_lines FOR
            SELECT sd.desc_val line_message, pk_sysconfig.get_config(l_domain_graph || '_' || sd.val, i_prof) coords
              FROM sys_domain sd
             WHERE sd.code_domain = l_domain_graph
               AND sd.id_language = i_lang
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.flg_available = g_available
             ORDER BY sd.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, 'GET_GRAPH_SCALES', g_error, SQLCODE, SQLERRM, FALSE, 'S', NULL, o_error);
    END get_delivery_graph_scales;
    --
    /********************************************************************************************
    * Checks if the vs_read is from the fetus
    *
    * @param i_vs_read               vital sign read id
    *         
    * @return                        1 - if the vs_read is from the fetus; 0 - Otherwise
    *
    * @author                        Alexandre Santos
    * @version                       1.0    
    * @since                         01-10-2009
    ********************************************************************************************/
    FUNCTION check_vs_read_from_fetus(i_vs_read IN vital_sign_read.id_vital_sign_read%TYPE) RETURN NUMBER IS
        l_is_from_fetus NUMBER := 0;
    BEGIN
        BEGIN
            SELECT decode(COUNT(*), 0, 0, 1)
              INTO l_is_from_fetus
              FROM vital_sign_pregnancy vsp
             WHERE vsp.id_vital_sign_read = i_vs_read
               AND vsp.fetus_number > 0;
        EXCEPTION
            WHEN no_data_found THEN
                l_is_from_fetus := 0;
        END;
    
        RETURN l_is_from_fetus;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END check_vs_read_from_fetus;

    /********************************************************************************************
    * Get the newborn list
    *
    * @param i_lang           language id
    * @param i_prof           professional, software and institution ids
    * @param i_episode        episode id
    * @param i_patient        patient id
    * @param i_discharge      discharge id
    * @param o_labels         label list
    * @param o_conditions     condition list
    * @param o_newborns       newborn list
    * @param o_newborns       error message
    *         
    * @return                 true or false on success or error                       
    *
    * @author                 Vanessa Barsottelli                       
    * @version                2.7.0
    * @since                  10.11.2016                         
    ********************************************************************************************/
    FUNCTION get_newborns
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_discharge  IN discharge.id_discharge%TYPE,
        o_labels     OUT pk_types.cursor_type,
        o_conditions OUT pk_types.cursor_type,
        o_newborns   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_msg_title     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'WOMAN_HEALTH_T169');
        l_msg_subtitle  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'WOMAN_HEALTH_T170');
        l_msg_name      sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'WOMAN_HEALTH_T171');
        l_msg_gender    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'WOMAN_HEALTH_T172');
        l_msg_condition sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'WOMAN_HEALTH_T173');
    
        l_sc_show_popup sys_config.value%TYPE := pk_sysconfig.get_config('DISCHARGE_NEWBORN', i_prof);
    
        l_disch_type   discharge.flg_type%TYPE;
        l_disch_status discharge.flg_status%TYPE;
    BEGIN
    
        IF l_sc_show_popup = pk_alert_constant.g_yes
        THEN
            g_error := 'CHECK ID_DIAGNOSIS';
            IF i_discharge IS NOT NULL
            THEN
                g_error := 'GET DISCHARGE FLG_TYPE AND FLG_STATUS';
                SELECT d.flg_type, d.flg_status
                  INTO l_disch_type, l_disch_status
                  FROM discharge d
                 WHERE d.id_discharge = i_discharge;
            
                IF l_disch_type IN ('D', 'F')
                   AND l_disch_status = 'A'
                THEN
                    g_error := 'OPEN CURSOR O_LABELS';
                    OPEN o_labels FOR
                        SELECT l_msg_title     title,
                               l_msg_subtitle  subtitle,
                               l_msg_name      col_name_lbl,
                               l_msg_gender    col_gender_lbl,
                               l_msg_condition col_condition_lbl
                          FROM dual;
                
                    g_error := 'OPEN CURSOR O_CONDITIONS';
                    OPEN o_conditions FOR
                        SELECT /*+opt_estimate (table t rows=3)*/
                         t.val data, t.desc_val label
                          FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang          => i_lang,
                                                                              i_prof          => i_prof,
                                                                              i_code_dom      => 'DISCHARGE_NEWBORN.FLG_CONDITION',
                                                                              i_dep_clin_serv => NULL)) t
                         WHERE t.val <> pk_disposition.g_newborn_condition_u
                         ORDER BY t.rank;
                
                    g_error := 'OPEN CURSOR O_NEWBORNS';
                    OPEN o_newborns FOR
                        SELECT edd.id_pat_pregnancy,
                               edd.id_child_episode id_episode,
                               p.name newborn_name,
                               (SELECT pk_sysdomain.get_domain(i_code_dom => 'PATIENT.GENDER',
                                                               i_val      => p.gender,
                                                               i_lang     => i_lang)
                                  FROM dual) newborn_gender,
                               (SELECT pk_sysdomain.get_domain(i_code_dom => 'DISCHARGE_NEWBORN.FLG_CONDITION',
                                                               i_val      => dnb.flg_condition,
                                                               i_lang     => i_lang)
                                  FROM dual) newborn_condition,
                               dnb.flg_condition flg_newborn_condition
                          FROM epis_doc_delivery edd
                          JOIN episode e
                            ON e.id_episode = edd.id_child_episode
                          JOIN patient p
                            ON p.id_patient = e.id_patient
                          LEFT JOIN discharge_newborn dnb
                            ON dnb.id_pat_pregnancy = edd.id_pat_pregnancy
                           AND dnb.id_discharge = i_discharge
                           AND dnb.id_episode = edd.id_child_episode
                         WHERE edd.id_pat_pregnancy IN (SELECT p.id_pat_pregnancy
                                                          FROM pat_pregnancy p
                                                         WHERE p.id_patient = i_patient
                                                           AND p.id_episode = i_episode)
                         ORDER BY edd.child_number ASC;
                END IF;
            ELSE
                pk_types.open_my_cursor(o_labels);
                pk_types.open_my_cursor(o_conditions);
                pk_types.open_my_cursor(o_newborns);
            END IF;
        ELSE
            pk_types.open_my_cursor(o_labels);
            pk_types.open_my_cursor(o_conditions);
            pk_types.open_my_cursor(o_newborns);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_labels);
            pk_types.open_my_cursor(o_conditions);
            pk_types.open_my_cursor(o_newborns);
            RETURN FALSE;
    END;

    FUNCTION get_delivery_value
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE DEFAULT NULL,
        i_pat_pregnancy    IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_child_number     IN epis_doc_delivery.child_number%TYPE,
        i_doc_area         IN doc_area.id_doc_area%TYPE,
        i_doc_template     IN doc_template.id_doc_template%TYPE DEFAULT NULL,
        i_doc_component    IN doc_component.id_doc_component%TYPE DEFAULT NULL,
        i_doc_int_name     IN documentation.internal_name%TYPE DEFAULT NULL,
        i_doc_element      IN doc_element.id_doc_element%TYPE DEFAULT NULL,
        i_mask             IN VARCHAR2 DEFAULT NULL,
        i_check_elemnt     IN VARCHAR2 DEFAULT 'N',
        i_element_int_name IN VARCHAR2 DEFAULT NULL,
        i_show_internal    IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_return   VARCHAR2(4000 CHAR);
        tbl_return table_varchar;
    
        l_comp_person_cert      doc_component.id_doc_component%TYPE := 132071;
        l_elem_person_cert_pedi doc_element.id_doc_element%TYPE := 2783172;
        l_elem_person_cert_othr doc_element.id_doc_element%TYPE := 2783173;
        l_elem_person_cert_atrz doc_element.id_doc_element%TYPE := 2783175;
        l_elem_person_cert_gino doc_element.id_doc_element%TYPE := 2783178;
    
        l_doc_area_newborn doc_area.id_doc_area%TYPE := 1048;
    BEGIN
    
        IF i_doc_area IN (pk_pregnancy_core.g_doc_area_obs_idx_tmpl, pk_past_history.g_doc_area_cong_anom)
        THEN
            SELECT pk_delivery.get_doc_element_value(i_lang,
                                                     i_prof,
                                                     t.flg_type,
                                                     t.value,
                                                     t.id_content,
                                                     i_mask,
                                                     i_doc_element,
                                                     comp_internal,
                                                     element_internal,
                                                     i_show_internal)
              BULK COLLECT
              INTO tbl_return
              FROM (SELECT CASE
                                WHEN i_check_elemnt = g_yes
                                     AND i_doc_component = l_comp_person_cert
                                     AND de.id_doc_element IN (l_elem_person_cert_pedi,
                                                               l_elem_person_cert_othr,
                                                               l_elem_person_cert_atrz,
                                                               l_elem_person_cert_gino) THEN
                                 'S'
                                ELSE
                                 de.flg_type
                            END flg_type,
                           edd.value,
                           c.id_content,
                           d.internal_name comp_internal,
                           de.internal_name element_internal,
                           row_number() over(PARTITION BY ed.id_doc_area ORDER BY ed.dt_creation_tstz DESC) rn
                      FROM epis_documentation ed
                      JOIN epis_documentation_det edd
                        ON edd.id_epis_documentation = ed.id_epis_documentation
                      JOIN documentation d
                        ON d.id_documentation = edd.id_documentation
                      JOIN doc_element de
                        ON de.id_doc_element = edd.id_doc_element
                      JOIN doc_element_crit c
                        ON c.id_doc_element_crit = edd.id_doc_element_crit
                     WHERE ed.flg_status = g_active
                       AND ed.id_doc_area = i_doc_area
                       AND ed.id_episode IN (SELECT id_episode
                                               FROM episode
                                              WHERE id_patient = i_patient)
                       AND (d.internal_name = i_doc_int_name OR i_doc_int_name IS NULL)
                       AND (de.internal_name = i_element_int_name OR i_element_int_name IS NULL)) t
             WHERE t.rn = 1;
        ELSE
            SELECT pk_delivery.get_doc_element_value(i_lang,
                                                     i_prof,
                                                     t.flg_type,
                                                     t.value,
                                                     t.id_content,
                                                     i_mask,
                                                     i_doc_element,
                                                     comp_internal,
                                                     element_internal,
                                                     i_show_internal)
              BULK COLLECT
              INTO tbl_return
              FROM (SELECT CASE
                                WHEN i_check_elemnt = g_yes
                                     AND i_doc_component = l_comp_person_cert
                                     AND de.id_doc_element IN (l_elem_person_cert_pedi,
                                                               l_elem_person_cert_othr,
                                                               l_elem_person_cert_atrz,
                                                               l_elem_person_cert_gino) THEN
                                 'S'
                                ELSE
                                 de.flg_type
                            END flg_type,
                           edd.value,
                           c.id_content,
                           d.internal_name comp_internal,
                           de.internal_name element_internal,
                           row_number() over(PARTITION BY edoc.id_pat_pregnancy ORDER BY ed.dt_creation_tstz DESC) rn
                      FROM epis_doc_delivery edoc
                      JOIN epis_documentation ed
                        ON ed.id_epis_documentation = edoc.id_epis_documentation
                      JOIN epis_documentation_det edd
                        ON edd.id_epis_documentation = ed.id_epis_documentation
                      JOIN documentation d
                        ON d.id_documentation = edd.id_documentation
                      JOIN doc_element de
                        ON de.id_doc_element = edd.id_doc_element
                      JOIN doc_element_crit c
                        ON c.id_doc_element_crit = edd.id_doc_element_crit
                     WHERE edoc.id_pat_pregnancy = i_pat_pregnancy
                       AND ed.flg_status = g_active
                       AND ed.id_doc_area = i_doc_area
                       AND (edoc.child_number = i_child_number AND ed.id_doc_area = l_doc_area_newborn OR
                           edoc.child_number IS NULL)
                       AND (d.internal_name = i_doc_int_name OR i_doc_int_name IS NULL)
                       AND (de.internal_name = i_element_int_name OR i_element_int_name IS NULL)) t
             WHERE t.rn = 1;
        END IF;
    
        IF tbl_return.count > 0
        THEN
            l_return := tbl_return(1);
        END IF;
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_delivery_value;

    FUNCTION exists_birth_certificate
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_child_number  IN epis_doc_delivery.child_number%TYPE
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(0100 CHAR);
    BEGIN
    
        SELECT decode(COUNT(1), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes)
          INTO l_return
          FROM (SELECT row_number() over(PARTITION BY edoc.id_pat_pregnancy, ed.id_episode ORDER BY ed.dt_creation_tstz DESC) rn
                  FROM epis_doc_delivery edoc
                  JOIN epis_documentation ed
                    ON ed.id_epis_documentation = edoc.id_epis_documentation
                   AND ed.flg_status = g_active
                 WHERE edoc.id_pat_pregnancy = i_pat_pregnancy
                   AND edoc.child_number = i_child_number
                   AND ed.id_doc_area = 1048
                   AND ed.id_doc_template = 505210) t
         WHERE t.rn = 1;
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END;

    FUNCTION get_birth_certificate_data
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_child_number  IN epis_doc_delivery.child_number%TYPE,
        i_flg_edition   IN epis_documentation.flg_edition_type%TYPE DEFAULT 'N',
        i_data_show     IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_prof_name professional.name%TYPE;
        l_date      VARCHAR2(4000 CHAR);
        l_return    VARCHAR2(4000 CHAR);
    
        k_prof_name       CONSTANT VARCHAR2(0100 CHAR) := 'PROF_NAME';
        k_reg_date        CONSTANT VARCHAR2(0100 CHAR) := 'REG_DATE';
        k_street_type     CONSTANT VARCHAR2(0100 CHAR) := 'STREET_TYPE';
        k_street          CONSTANT VARCHAR2(0100 CHAR) := 'STREET';
        k_outside_number  CONSTANT VARCHAR2(0100 CHAR) := 'OUTSIDE_NUMBER';
        k_inside_number   CONSTANT VARCHAR2(0100 CHAR) := 'INSIDE_NUMBER';
        k_settlement_type CONSTANT VARCHAR2(0100 CHAR) := 'SETTLEMENT_TYPE';
        k_settlement      CONSTANT VARCHAR2(0100 CHAR) := 'SETTLEMENT';
        k_postal_code     CONSTANT VARCHAR2(0100 CHAR) := 'POSTAL_CODE';
        k_code_entity     CONSTANT VARCHAR2(0100 CHAR) := 'CODE_ENTITY';
        k_code_municip    CONSTANT VARCHAR2(0100 CHAR) := 'CODE_MUNICIP';
        k_code_location   CONSTANT VARCHAR2(0100 CHAR) := 'CODE_LOCATION';
        k_phone_number    CONSTANT VARCHAR2(0100 CHAR) := 'PHONE_NUMBER';
    BEGIN
    
        IF exists_birth_certificate(i_lang          => i_lang,
                                    i_prof          => i_prof,
                                    i_pat_pregnancy => i_pat_pregnancy,
                                    i_child_number  => i_child_number) = pk_alert_constant.g_yes
        THEN
            IF i_data_show = k_prof_name
            THEN
                IF i_flg_edition = pk_touch_option.g_flg_edition_type_new
                THEN
                    l_return := 'SINAC';
                ELSE
                    BEGIN
                        SELECT 'SINAC'
                          INTO l_prof_name
                          FROM dual
                         WHERE EXISTS (SELECT 1
                                  FROM epis_doc_delivery edoc
                                  JOIN epis_documentation ed
                                    ON ed.id_epis_documentation = edoc.id_epis_documentation
                                 WHERE edoc.id_pat_pregnancy = i_pat_pregnancy
                                   AND edoc.child_number = i_child_number
                                   AND ed.id_doc_area = 1048
                                   AND ed.id_doc_template = 505210
                                   AND ed.flg_edition_type = pk_touch_option.g_flg_edition_type_edit);
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_prof_name := NULL;
                    END;
                    l_return := l_prof_name;
                END IF;
            ELSIF i_data_show = k_reg_date
            THEN
                SELECT CASE t.flg_edition_type
                           WHEN 'N' THEN
                            to_char(t.dt_creation_tstz, 'DD/MM/YYYY')
                           WHEN 'E' THEN
                            to_char(t.dt_last_update_tstz, 'DD/MM/YYYY')
                           ELSE
                            NULL
                       END dt
                  INTO l_date
                  FROM (SELECT ed.flg_edition_type,
                               ed.dt_creation_tstz,
                               ed.dt_last_update_tstz,
                               row_number() over(PARTITION BY edoc.id_pat_pregnancy, ed.id_episode ORDER BY ed.dt_creation_tstz DESC) rn
                          FROM epis_doc_delivery edoc
                          JOIN epis_documentation ed
                            ON ed.id_epis_documentation = edoc.id_epis_documentation
                         WHERE edoc.id_pat_pregnancy = i_pat_pregnancy
                           AND edoc.child_number = i_child_number
                           AND ed.id_doc_area = 1048
                           AND ed.id_doc_template = 505210
                           AND ed.flg_edition_type = i_flg_edition) t
                 WHERE ((i_flg_edition = pk_touch_option.g_flg_edition_type_new) OR
                       (i_flg_edition = pk_touch_option.g_flg_edition_type_edit AND t.rn = 1));
            
                l_return := l_date;
            ELSIF i_data_show = k_street_type
            THEN
                l_return := pk_backoffice.get_inst_field(i_lang, i_prof, i_prof.institution, k_street_type);
            ELSIF i_data_show = k_street
            THEN
                l_return := pk_backoffice.get_inst_field(i_lang, i_prof, i_prof.institution, k_street);
            ELSIF i_data_show = k_outside_number
            THEN
                l_return := pk_backoffice.get_inst_field(i_lang, i_prof, i_prof.institution, k_outside_number);
            ELSIF i_data_show = k_inside_number
            THEN
                l_return := pk_backoffice.get_inst_field(i_lang, i_prof, i_prof.institution, k_inside_number);
            ELSIF i_data_show = k_settlement_type
            THEN
                l_return := pk_backoffice.get_inst_field(i_lang, i_prof, i_prof.institution, k_settlement_type);
            ELSIF i_data_show = k_settlement
            THEN
                l_return := pk_backoffice.get_inst_field(i_lang, i_prof, i_prof.institution, k_settlement);
            ELSIF i_data_show = k_postal_code
            THEN
                l_return := pk_backoffice.get_inst_field(i_lang, i_prof, i_prof.institution, k_postal_code);
            ELSIF i_data_show = k_code_entity
            THEN
                l_return := pk_backoffice.get_inst_field(i_lang, i_prof, i_prof.institution, k_code_entity);
            ELSIF i_data_show = k_code_municip
            THEN
                l_return := pk_backoffice.get_inst_field(i_lang, i_prof, i_prof.institution, k_code_municip);
            ELSIF i_data_show = k_code_location
            THEN
                l_return := pk_backoffice.get_inst_field(i_lang, i_prof, i_prof.institution, k_code_location);
            ELSIF i_data_show = k_phone_number
            THEN
                l_return := pk_backoffice.get_inst_field(i_lang, i_prof, i_prof.institution, k_phone_number);
            ELSE
                l_return := NULL;
            END IF;
        END IF;
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_birth_certificate_data;

    FUNCTION get_delivery_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_fetus_number  IN pat_pregn_fetus.fetus_number%TYPE,
        i_doc_area      IN doc_area.id_doc_area%TYPE,
        i_doc_template  IN doc_template.id_doc_template%TYPE
    ) RETURN doc_element_crit.id_content%TYPE IS
        l_return         doc_element_crit.id_content%TYPE;
        l_doc_component  doc_component.id_doc_component%TYPE;
        l_tbl_birth_type table_varchar := table_varchar('BIRTH_TYPE_CP',
                                                        'BIRTH_TYPE_CS',
                                                        'BIRTH_TYPE_CF',
                                                        'BIRTH_TYPE_DF',
                                                        'BIRTH_TYPE_DV',
                                                        'BIRTH_TYPE_DC',
                                                        'BIRTH_TYPE_DT',
                                                        'BIRTH_TYPE_DE',
                                                        'BIRTH_TYPE_DP',
                                                        'BIRTH_TYPE_O',
                                                        'BIRTH_TYPE_N',
                                                        'BIRTH_TYPE_C');
    BEGIN
    
        SELECT d.id_doc_component
          INTO l_doc_component
          FROM documentation_ext de
         INNER JOIN TABLE(l_tbl_birth_type) t
            ON de.internal_name = t.column_value
         INNER JOIN doc_element del
            ON de.id_doc_element = del.id_doc_element
         INNER JOIN documentation d
            ON del.id_documentation = d.id_documentation
         INNER JOIN doc_template_area_doc dtad
            ON d.id_documentation = dtad.id_documentation
         WHERE dtad.id_doc_area = i_doc_area
           AND dtad.id_doc_template = i_doc_template
           AND pk_utils.str_token(de.value, 2, '|') = i_fetus_number
           AND rownum = 1;
    
        l_return := pk_delivery.get_delivery_value(i_lang          => i_lang,
                                                   i_prof          => i_prof,
                                                   i_pat_pregnancy => i_pat_pregnancy,
                                                   i_child_number  => i_fetus_number,
                                                   i_doc_area      => i_doc_area,
                                                   i_doc_template  => i_doc_template,
                                                   i_doc_component => l_doc_component);
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_delivery_type;

    FUNCTION is_place_of_birth_inst
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_birth_inst IN pat_birthplace.id_institution%TYPE
    ) RETURN VARCHAR2 IS
        l_place_of_birth pat_birthplace.id_institution%TYPE;
    BEGIN
    
        IF i_birth_inst IS NULL
        THEN
            SELECT id_institution
              INTO l_place_of_birth
              FROM v_birthplace_address_mx v
            
             WHERE v.id_patient = i_patient;
        ELSE
            l_place_of_birth := i_birth_inst;
        END IF;
        IF l_place_of_birth = i_prof.institution
        THEN
            RETURN pk_alert_constant.g_yes;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END is_place_of_birth_inst;

    FUNCTION verify_cancel_born_record
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE
    ) RETURN BOOLEAN IS
        l_count  NUMBER;
        l_return BOOLEAN;
    BEGIN
    
        SELECT COUNT(1)
          INTO l_count
          FROM documentation_ext de
         INNER JOIN doc_element del
            ON de.id_doc_element = del.id_doc_element
         INNER JOIN documentation d
            ON del.id_documentation = d.id_documentation
         INNER JOIN doc_template_area_doc dtad
            ON d.id_documentation = dtad.id_documentation
         INNER JOIN epis_documentation ed
            ON ed.id_doc_template = dtad.id_doc_template
         WHERE dtad.id_doc_area = pk_pregnancy_core.g_doc_area_born
           AND ed.id_epis_documentation = i_epis_documentation;
    
        IF l_count > 0
        THEN
            l_return := TRUE;
        ELSE
            l_return := FALSE;
        END IF;
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END verify_cancel_born_record;

    FUNCTION get_born_anomaly_acelrn
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_data_show IN VARCHAR2,
        i_text_show IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_acelrn VARCHAR2(4000 CHAR);
        l_na     VARCHAR(0100 CHAR);
    
        k_acelrn    CONSTANT VARCHAR2(0100 CHAR) := 'ANOM_CONG1';
        k_acelrn2   CONSTANT VARCHAR2(0100 CHAR) := 'ANOM_CONG2';
        k_acelrn_na CONSTANT VARCHAR2(0100 CHAR) := 'N_ANOM_CONG';
        k_doc_area NUMBER := 52;
    BEGIN
        l_na := pk_delivery.get_delivery_value(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_patient          => i_patient,
                                               i_pat_pregnancy    => NULL,
                                               i_child_number     => NULL,
                                               i_doc_area         => k_doc_area,
                                               i_doc_int_name     => k_acelrn,
                                               i_element_int_name => k_acelrn_na);
    
        IF l_na IS NULL
        THEN
            l_acelrn := pk_delivery.get_delivery_value(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_patient       => i_patient,
                                                       i_pat_pregnancy => NULL,
                                                       i_child_number  => NULL,
                                                       i_doc_area      => k_doc_area,
                                                       i_doc_int_name  => i_data_show);
        ELSE
            l_acelrn := i_text_show;
        END IF;
    
        RETURN l_acelrn;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_born_anomaly_acelrn;

    FUNCTION get_born_anomaly_cve
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_data_show    IN VARCHAR2,
        i_text_show    IN VARCHAR2,
        i_text_na_show IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000 CHAR);
    
        l_anomalies VARCHAR(4000 CHAR);
        l_acelrn    VARCHAR2(4000 CHAR);
        l_na        VARCHAR(0100 CHAR);
    
        k_cve_cie   CONSTANT VARCHAR2(0100 CHAR) := 'CVE_CIE';
        k_cve_cie2  CONSTANT VARCHAR2(0100 CHAR) := 'CVE_CIE2';
        k_acelrn    CONSTANT VARCHAR2(0100 CHAR) := 'ANOM_CONG1';
        k_acelrn2   CONSTANT VARCHAR2(0100 CHAR) := 'ANOM_CONG2';
        k_acelrn_na CONSTANT VARCHAR2(0100 CHAR) := 'N_ANOM_CONG';
        k_doc_area NUMBER := 52;
    
    BEGIN
    
        l_na := pk_delivery.get_delivery_value(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_patient          => i_patient,
                                               i_pat_pregnancy    => NULL,
                                               i_child_number     => NULL,
                                               i_doc_area         => k_doc_area,
                                               i_doc_int_name     => k_acelrn,
                                               i_element_int_name => k_acelrn_na);
        IF l_na IS NOT NULL
        THEN
            l_return := i_text_na_show;
        ELSE
            l_anomalies := pk_diagnosis.get_congenital_anomalies(i_lang        => i_lang,
                                                                 i_prof        => i_prof,
                                                                 i_id_episode  => i_episode,
                                                                 i_nr_anomalie => CASE
                                                                                      WHEN i_data_show = k_cve_cie THEN
                                                                                       1
                                                                                      WHEN i_data_show = k_cve_cie2 THEN
                                                                                       2
                                                                                      ELSE
                                                                                       0
                                                                                  END);
            IF l_anomalies IS NULL
            THEN
            
                l_acelrn := pk_delivery.get_delivery_value(i_lang          => i_lang,
                                                           i_prof          => i_prof,
                                                           i_patient       => i_patient,
                                                           i_pat_pregnancy => NULL,
                                                           i_child_number  => NULL,
                                                           i_doc_area      => k_doc_area,
                                                           i_doc_int_name  => CASE
                                                                                  WHEN i_data_show = k_cve_cie THEN
                                                                                   k_acelrn
                                                                                  WHEN i_data_show = k_cve_cie2 THEN
                                                                                   k_acelrn2
                                                                              END);
                IF l_acelrn IS NOT NULL
                THEN
                    l_return := i_text_show;
                ELSE
                    l_return := NULL;
                END IF;
            
            ELSE
                l_return := l_anomalies;
            END IF;
        END IF;
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_born_anomaly_cve;

    FUNCTION get_cancelled_folios
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_child_number  IN epis_doc_delivery.child_number%TYPE,
        i_dt_cancel     IN epis_documentation.dt_cancel_tstz%TYPE
    ) RETURN VARCHAR2 IS
        l_return   VARCHAR2(4000 CHAR);
        tbl_return table_varchar;
    
        l_doc_area_newborn doc_area.id_doc_area%TYPE := 1048;
    BEGIN
    
        SELECT pk_touch_option.get_doc_element_value(i_lang, i_prof, t.flg_type, t.value, t.id_content, NULL, 2788787)
          BULK COLLECT
          INTO tbl_return
          FROM (SELECT de.flg_type,
                       edd.value,
                       c.id_content,
                       row_number() over(PARTITION BY edoc.id_pat_pregnancy ORDER BY ed.dt_creation_tstz DESC) rn
                  FROM epis_doc_delivery edoc
                  JOIN epis_documentation ed
                    ON ed.id_epis_documentation = edoc.id_epis_documentation
                  JOIN epis_documentation_det edd
                    ON edd.id_epis_documentation = ed.id_epis_documentation
                  JOIN documentation d
                    ON d.id_documentation = edd.id_documentation
                  JOIN doc_element de
                    ON de.id_doc_element = edd.id_doc_element
                  JOIN doc_element_crit c
                    ON c.id_doc_element_crit = edd.id_doc_element_crit
                 WHERE edoc.id_pat_pregnancy = i_pat_pregnancy
                   AND ed.flg_status = 'C'
                   AND ed.id_doc_area = 1048
                   AND d.id_doc_template = 505210
                   AND d.id_doc_component = 133203
                   AND edd.id_doc_element = 2788787
                   AND ed.dt_cancel_tstz = i_dt_cancel
                   AND edoc.child_number = i_child_number
                   AND ed.id_doc_area = l_doc_area_newborn) t
         WHERE t.rn = 1;
    
        IF tbl_return.count > 0
        THEN
            l_return := tbl_return(1);
        END IF;
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_cancelled_folios;

    FUNCTION get_doc_element_value
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_type          IN doc_element.flg_type%TYPE,
        i_value             IN epis_documentation_det.value%TYPE,
        i_id_content        IN doc_element_crit.id_content%TYPE,
        i_mask              IN VARCHAR2 DEFAULT NULL,
        i_doc_element       IN doc_element.id_doc_element%TYPE DEFAULT NULL,
        i_doc_comp_internal IN documentation.internal_name%TYPE DEFAULT NULL,
        i_doc_elem_internal IN doc_element.internal_name%TYPE DEFAULT NULL,
        i_show_internal     IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_value            VARCHAR2(4000 CHAR);
        l_value_parts      table_varchar2;
        l_int_name_elem_99 table_varchar := table_varchar();
        l_si_99            NUMBER := 99;
        l_folio_si         NUMBER := 999999999;
        l_error_out        t_error_out;
    BEGIN
        CASE
            WHEN i_flg_type = pk_touch_option.g_elem_flg_type_comp_date THEN
                l_value_parts := pk_utils.str_split(i_value, '|');
                l_value       := to_char(to_timestamp(l_value_parts(1), l_value_parts(2)),
                                         nvl(i_mask, 'YYYYMMDDHH24MISS'));
            WHEN i_flg_type IN (pk_touch_option.g_elem_flg_type_comp_numeric,
                                pk_touch_option.g_elem_flg_type_simple_number,
                                pk_touch_option.g_elem_flg_type_text,
                                pk_touch_option.g_elem_flg_type_comp_text) THEN
                l_value := i_value;
            WHEN i_doc_elem_internal = g_int_name_folio_si THEN
                l_value := l_folio_si;
            WHEN i_doc_elem_internal IN (g_int_name_survivor_si,
                                         g_int_name_born_alive_si,
                                         g_int_name_born_death_si,
                                         g_int_name_pregn_num_si,
                                         g_int_name_order_nasc_si) THEN
                l_value := l_si_99;
            WHEN i_show_internal = pk_alert_constant.g_yes THEN
                l_value := i_doc_elem_internal;
            WHEN i_flg_type = pk_touch_option.g_elem_flg_type_mchoice_single THEN
                CASE
                    WHEN i_value IN ('1', 'S') THEN
                        l_value := 'Y';
                    WHEN i_value IN ('2', 'N') THEN
                        l_value := 'N';
                    WHEN i_value IN ('3', 'NE') THEN
                        l_value := 'NE';
                    WHEN i_value = 'SE' THEN
                        l_value := 'SI';
                    ELSE
                        l_value := i_value;
                END CASE;
            ELSE
                l_value := i_id_content;
        END CASE;
    
        RETURN l_value;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_doc_element_value;

    FUNCTION get_death_folio_cert
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE
    ) RETURN NUMBER IS
    
        l_mother_death doc_element.internal_name%TYPE;
        l_value        VARCHAR2(2000 CHAR);
    BEGIN
    
        l_mother_death := pk_delivery.get_delivery_value(i_lang          => i_lang,
                                                         i_prof          => NULL,
                                                         i_patient       => i_patient,
                                                         i_pat_pregnancy => i_pat_pregnancy,
                                                         i_child_number  => NULL,
                                                         i_doc_area      => 1097,
                                                         i_doc_int_name  => g_int_mother_survivor,
                                                         i_show_internal => pk_alert_constant.g_yes);
    
        IF l_mother_death = g_int_mother_death -- mother death 
        THEN
            --          get folio
            l_value := pk_delivery.get_delivery_value(i_lang          => i_lang,
                                                      i_prof          => NULL,
                                                      i_patient       => i_patient,
                                                      i_pat_pregnancy => i_pat_pregnancy,
                                                      i_child_number  => NULL,
                                                      i_doc_area      => 1097,
                                                      i_doc_int_name  => g_int_name_folio);
        END IF;
    
        RETURN l_value;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_death_folio_cert;

    /********************************************************************************************
    * Get newborn gestation age
    *
    * @param i_lang             The language ID
    * @param i_prof             Object (professional ID, institution ID, software ID)
    * @param i_patient          Patient ID
    * @param o_ga_age           gestation age
    * @param o_error            Error message
    *
    * @return                   true or false on success or error
    *
    * @author                   Lillian Lu
    * @version                  2.7.2.6
    * @since                    2018-02-23
    **********************************************************************************************/
    FUNCTION get_newborn_delivery_weeks
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        o_ga_age  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_weeks  NUMBER;
        l_days   NUMBER;
        l_ga_age VARCHAR2(50);
    
        l_dt_init_preg pat_pregnancy.dt_init_pregnancy%TYPE;
        l_dt_reg       pat_pregnancy.dt_intervention%TYPE;
    
    BEGIN
    
        BEGIN
            SELECT pp.dt_init_pregnancy, pp.dt_intervention
              INTO l_dt_init_preg, l_dt_reg
              FROM pat_pregnancy pp
              JOIN epis_doc_delivery edd
                ON edd.id_pat_pregnancy = pp.id_pat_pregnancy
              JOIN episode e
                ON e.id_episode = edd.id_child_episode
             WHERE e.id_patient = i_patient
               AND pp.flg_status = pk_pregnancy_core.g_pat_pregn_past
               AND rownum = 1;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN TRUE;
        END;
    
        g_error := 'GET PREGNANCY WEEKS';
        l_weeks := pk_pregnancy_api.get_pregnancy_weeks(i_prof, l_dt_init_preg, l_dt_reg, NULL);
        l_days  := pk_pregnancy_api.get_pregnancy_days(i_prof, l_dt_init_preg, l_dt_reg, NULL);
    
        IF (l_weeks IS NULL AND l_days IS NULL)
        THEN
            l_ga_age := pk_message.get_message(i_lang, i_prof, 'PAT_PREGNANCY_M007');
        ELSE
        
            IF l_days > 0
            THEN
                l_ga_age := ' ' || l_days || pk_message.get_message(i_lang, i_prof, 'DAY_SIGN');
            END IF;
        
            l_ga_age := l_weeks || pk_message.get_message(i_lang, i_prof, 'WOMAN_HEALTH_T063') || l_ga_age;
        
        END IF;
    
        o_ga_age := l_ga_age;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_NEWBORN_DELIVERY_WEEKS', g_error, SQLERRM, o_error);
    END get_newborn_delivery_weeks;

    FUNCTION set_child_episode
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_child_number       IN epis_doc_delivery.child_number%TYPE,
        i_patient_child      IN patient.id_patient%TYPE,
        i_child_episode      IN episode.id_episode%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        IF NOT set_child_episode_internal(i_lang               => i_lang,
                                          i_prof               => i_prof,
                                          i_patient            => i_patient,
                                          i_pat_pregnancy      => i_pat_pregnancy,
                                          i_epis_documentation => i_epis_documentation,
                                          i_child_number       => i_child_number,
                                          i_patient_child      => i_patient_child,
                                          i_child_episode      => i_child_episode,
                                          i_commit             => pk_alert_constant.g_yes,
                                          o_error              => o_error)
        THEN
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'SET_CHILD_EPISODE', g_error, SQLERRM, o_error);
    END set_child_episode;

    /********************************************************************************************
    * Get patient delivery information
    *
    * @param i_lang             The language ID
    * @param i_prof             Object (professional ID, institution ID, software ID)
    * @param i_patient          Patient ID
    * @param o_info             cursor with all information
    * @param o_error            Error message
    *
    * @return                   true or false on success or error
    *
    * @author                   Elisabete Bugalho
    * @version                  2.7.4.0
    * @since                    2018-09-10
    **********************************************************************************************/
    FUNCTION get_patient_delivery_info
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        o_info    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_weeks  NUMBER;
        l_days   NUMBER;
        l_ga_age VARCHAR2(50);
    
        l_dt_init_preg pat_pregnancy.dt_init_pregnancy%TYPE;
        l_dt_reg       pat_pregnancy.dt_intervention%TYPE;
    
    BEGIN
    
        OPEN o_info FOR
            SELECT t.n_children,
                   t.dt_birth,
                   pk_date_utils.date_char_tsz(i_lang, t.dt_birth, i_prof.institution, i_prof.software) dt_hour_birth,
                   t.attending,
                   t.position,
                   pk_date_utils.date_char_hour_tsz(i_lang, t.dt_birth, i_prof.institution, i_prof.software) hour_birth,
                   t.mother_mrn,
                   t.father_name,
                   t.mother_patient_id
              FROM (SELECT pp.n_children,
                           get_pat_dt_birth(i_lang, i_prof, pp.id_pat_pregnancy, g_type_dt_birth_e, edd.child_number) dt_birth,
                           
                           pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                            i_prof    => i_prof,
                                                            i_prof_id => ed.id_professional) attending,
                           pk_prof_utils.get_prof_speciality(i_lang => i_lang,
                                                             i_prof => profissional(ed.id_professional,
                                                                                    institution => i_prof.institution,
                                                                                    i_prof.software)) position,
                           cr.num_clin_record mother_mrn,
                           pk_touch_option.get_template_value(i_lang            => i_lang,
                                                              i_prof            => i_prof,
                                                              i_patient         => pp.id_patient,
                                                              i_episode         => ed.id_episode,
                                                              i_doc_area        => pk_summary_page.g_doc_area_father_data,
                                                              i_doc_int_name    => g_int_father_name,
                                                              i_show_id_content => pk_alert_constant.g_no,
                                                              i_show_doc_title  => pk_alert_constant.g_no) father_name,
                           pp.id_patient mother_patient_id
                      FROM pat_pregnancy pp
                      JOIN epis_doc_delivery edd
                        ON edd.id_pat_pregnancy = pp.id_pat_pregnancy
                      JOIN episode e
                        ON e.id_episode = edd.id_child_episode
                      JOIN epis_documentation ed
                        ON edd.id_epis_documentation = ed.id_epis_documentation
                      JOIN clin_record cr
                        ON cr.id_patient = pp.id_patient
                     WHERE e.id_patient = i_patient
                       AND pp.flg_status = pk_pregnancy_core.g_pat_pregn_past
                       AND cr.id_institution = i_prof.institution
                       AND cr.flg_status = pk_patient.g_clin_rec_active) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_PATIENT_DELIVERY_INFO', g_error, SQLERRM, o_error);
    END get_patient_delivery_info;

    /********************************************************************************************
    *  if the vs_read is from the fetus returns te fetus number
    *
    * @param i_vs_read               vital sign read id
    *         
    * @return                        0 or fetus number
    *
    * @author                        Elisabete Bugalho
    * @version                       2.8.4.0   
    * @since                        29-09-2021
    ********************************************************************************************/
    FUNCTION get_id_fetus_from_vs_read(i_vs_read IN vital_sign_read.id_vital_sign_read%TYPE) RETURN NUMBER IS
        l_id_from_fetus NUMBER := 0;
    BEGIN
        BEGIN
            SELECT vsp.fetus_number
              INTO l_id_from_fetus
              FROM vital_sign_pregnancy vsp
             WHERE vsp.id_vital_sign_read = i_vs_read
               AND vsp.fetus_number > 0;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_from_fetus := 0;
        END;
    
        RETURN l_id_from_fetus;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_id_fetus_from_vs_read;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

END pk_delivery;
/
