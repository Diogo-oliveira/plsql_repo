/*-- Last Change Revision: $Rev: 2055402 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2023-02-22 09:44:22 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_unit_measure IS

    /**
    * This function returns true if the two units are convertible
    *
    * @param i_unit_meas           Unit measure to convert.
    * @param i_unit_meas_def       Default unit measure
    *
    * @return boolean
    *
    * @author   F�bio Oliveira
    * @version  2.5.0.7
    * @since    2009/11/05
    */
    FUNCTION are_convertible
    (
        i_unit_meas     IN unit_measure_convert.id_unit_measure1%TYPE,
        i_unit_meas_def IN unit_measure.id_unit_measure%TYPE
    ) RETURN BOOLEAN IS
    
        l_are_convertible PLS_INTEGER;
    BEGIN
        IF i_unit_meas != i_unit_meas_def
        THEN
            SELECT decode((SELECT 1
                            FROM dual
                           WHERE EXISTS (SELECT 0
                                    FROM unit_measure_convert umc
                                   WHERE umc.id_unit_measure1 = i_unit_meas
                                     AND umc.id_unit_measure2 = i_unit_meas_def)),
                          1,
                          1,
                          0) convertible
              INTO l_are_convertible
              FROM dual;
        ELSE
            l_are_convertible := 1;
        END IF;
        --
        RETURN CASE l_are_convertible WHEN 1 THEN TRUE ELSE FALSE END;
        --
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END;

    FUNCTION tf_get_unit_measure_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_area IN VARCHAR2
    ) RETURN t_tbl_core_domain IS
    
        l_tbl_unit_measure table_number;
    
        l_tbl_um_duration        table_number := table_number(10374, 1041, 1039, 10375, 1127, 10373);
        l_tbl_um_execution       table_number := table_number(10374, 1041);
        l_tbl_regular_intervals  table_number := table_number(1041, 10374);
        l_tbl_um_rehab_frequency table_number := table_number(10375, 1127, 1039);
    
        l_ret   t_tbl_core_domain;
        l_error t_error_out;
    BEGIN
    
        IF i_area IN (pk_orders_constant.g_ds_procedure_request,
                      pk_orders_constant.g_ds_order_set_procedure,
                      'DS_UNIT_MEASURE_DURATION',
                      'DS_END_AFTER_N')
        THEN
            l_tbl_unit_measure := l_tbl_um_duration;
        ELSIF i_area = pk_orders_constant.g_ds_unit_measure_regular_intervals
        THEN
            l_tbl_unit_measure := l_tbl_regular_intervals;
        ELSIF i_area IN (pk_orders_constant.g_ds_health_education_order_execution,
                         pk_orders_constant.g_ds_health_education_execution)
        THEN
            l_tbl_unit_measure := l_tbl_um_execution;
        ELSIF i_area IN (pk_orders_constant.g_ds_rehab_treatment)
        THEN
            l_tbl_unit_measure := l_tbl_um_rehab_frequency;
        ELSIF i_area = 'GET_UNIT_MEASURE_DAYS'
        THEN
            l_tbl_unit_measure := table_number(1039);
        ELSIF i_area = 'GET_UNIT_MEASURE_SURGERY'
        THEN
            l_tbl_unit_measure := table_number(1041);
        END IF;
    
        g_error := 'OPEN L_RET';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => tt.label,
                                         domain_value  => tt.data,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT /*+opt_estimate(table s rows=1)*/
                         t.column_value data,
                         pk_unit_measure.get_unit_measure_description(i_lang, i_prof, t.column_value) label
                          FROM TABLE(l_tbl_unit_measure) t
                         ORDER BY t.column_value) tt
                 ORDER BY tt.label);
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TF_GET_UNIT_MEASURE_LIST',
                                              l_error);
            RETURN t_tbl_core_domain();
    END tf_get_unit_measure_list;

    FUNCTION get_unit_measure_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_area  IN VARCHAR2,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN o_list';
        OPEN o_list FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.domain_value id_unit_measure, t.desc_domain unit_measure_desc
              FROM TABLE(pk_unit_measure.tf_get_unit_measure_list(i_lang => i_lang, i_prof => i_prof, i_area => i_area)) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_UNIT_MEASURE_LIST',
                                              o_error);
            RETURN FALSE;
    END get_unit_measure_list;

    /**
    * This function returns 0 if the two units aren't convertible
    * or 1 if are convertible from i_unit_meas to i_unit_meas_def
    * or 2 if at least they are convertible from i_unit_meas_def to i_unit_meas
    *
    * @param i_unit_meas           Unit measure to convert.
    * @param i_unit_meas_def       Default unit measure
    *
    * @return number
    *
    * @author   Vitor Reis
    * @version  2.6.5.0
    * @since    08/05/2015
    */
    FUNCTION get_conversion_direction
    (
        i_unit_meas_1 IN unit_measure.id_unit_measure%TYPE,
        i_unit_meas_2 IN unit_measure.id_unit_measure%TYPE
    ) RETURN NUMBER IS
    
        l_return NUMBER := 0;
    
        l_um1 unit_measure.id_unit_measure%TYPE;
        l_um2 unit_measure.id_unit_measure%TYPE;
    
    BEGIN
    
        <<loop_through_ways>>
        FOR i IN 1 .. 2
        LOOP
            CASE i
                WHEN 1 THEN
                    l_um1 := i_unit_meas_1;
                    l_um2 := i_unit_meas_2;
                WHEN 2 THEN
                    l_um1 := i_unit_meas_2;
                    l_um2 := i_unit_meas_1;
            END CASE;
        
            IF are_convertible(i_unit_meas => l_um1, i_unit_meas_def => l_um2)
            THEN
                l_return := i;
            
                EXIT loop_through_ways;
            END IF;
        
        END LOOP loop_through_ways;
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_conversion_direction;

    /**
    * This function returns the conversion value between diferent measure units
    *
    * @param i_value               Value to convert.
    * @param i_unit_meas           Unit measure to convert.
    * @param i_unit_meas_def       Default unit measure
    *
    * @author   Emilia Taborda
    * @version  1.0
    * @since    2006/08/24
    */
    FUNCTION get_unit_mea_conversion_base
    (
        i_value         IN vital_sign_read.value%TYPE,
        i_unit_meas     IN unit_measure_convert.id_unit_measure1%TYPE,
        i_unit_meas_def IN unit_measure.id_unit_measure%TYPE,
        i_decimals      IN NUMBER
    ) RETURN NUMBER IS
        l_formula      unit_measure_convert.formula%TYPE;
        l_decimals     unit_measure_convert.decimals%TYPE;
        l_for_result   NUMBER(24, 6);
        l_result_final NUMBER(24, 6);
        --
        CURSOR c_formule IS
            SELECT formula, decimals
              FROM unit_measure_convert
             WHERE id_unit_measure1 = i_unit_meas
               AND id_unit_measure2 = i_unit_meas_def;
    BEGIN
    
        IF i_unit_meas != i_unit_meas_def
        THEN
            OPEN c_formule;
            FETCH c_formule
                INTO l_formula, l_decimals;
            CLOSE c_formule;
            --
            EXECUTE IMMEDIATE l_formula
                INTO l_for_result
                USING i_value;
            --
        
            IF i_decimals IS NOT NULL
            THEN
                l_decimals := i_decimals;
            END IF;
        
            l_result_final := round(l_for_result, l_decimals);
        
        ELSIF i_unit_meas = i_unit_meas_def
        THEN
            l_result_final := i_value;
        ELSE
            l_result_final := NULL;
        END IF;
        --
        RETURN l_result_final;
        --
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_unit_mea_conversion_base;

    FUNCTION get_unit_mea_conversion
    (
        i_value         IN vital_sign_read.value%TYPE,
        i_unit_meas     IN unit_measure_convert.id_unit_measure1%TYPE,
        i_unit_meas_def IN unit_measure.id_unit_measure%TYPE
    ) RETURN NUMBER IS
    BEGIN
    
        RETURN get_unit_mea_conversion_base(i_value, i_unit_meas, i_unit_meas_def, NULL);
    
    END get_unit_mea_conversion;

    FUNCTION get_unit_mea_conversion
    (
        i_value         IN vital_sign_read.value%TYPE,
        i_unit_meas     IN unit_measure_convert.id_unit_measure1%TYPE,
        i_unit_meas_def IN unit_measure.id_unit_measure%TYPE,
        i_decimals      IN NUMBER
    ) RETURN NUMBER IS
    BEGIN
    
        RETURN get_unit_mea_conversion_base(i_value, i_unit_meas, i_unit_meas_def, i_decimals);
    
    END get_unit_mea_conversion;

    /********************************************************************************************
    * Returns the Unit of Measure abbreviation
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param i_unit_measure              Unit of measure ID
    * @return                            Unit of measure abbreviation
    *
    * @author  ARIEL.MACHADO
    * @version 2.5
    * @since   25-Jun-09
    **********************************************************************************************/
    FUNCTION get_uom_abbreviation
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_unit_measure IN unit_measure.id_unit_measure%TYPE
    ) RETURN VARCHAR2 IS
        l_abbreviation VARCHAR2(4000);
    BEGIN
    
        SELECT coalesce(pk_translation.get_translation(i_lang, uom.code_unit_measure_abrv),
                        pk_translation.get_translation(i_lang, uom.code_unit_measure)) uom_abbrev
          INTO l_abbreviation
          FROM unit_measure uom
         WHERE uom.id_unit_measure = i_unit_measure;
    
        RETURN l_abbreviation;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_package_owner, g_package_name, '');
                l_ret := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                RETURN NULL;
            END;
    END get_uom_abbreviation;

    /********************************************************************************************
    * Returns the unit measure description
    *
    * @param    i_lang              Preferred language ID
    * @param    i_prof              Object (ID of professional, ID of institution, ID of software)
    * @param    i_unit_measure      Unit measure ID
    *
    * @return   varchar2            Unit of measure abbreviation
    *
    * @author  Tiago Silva
    * @since   02/07/2010
    **********************************************************************************************/
    FUNCTION get_unit_measure_description
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_unit_measure IN unit_measure.id_unit_measure%TYPE
    ) RETURN VARCHAR2 IS
        l_description VARCHAR2(1000 CHAR);
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_unit_measure_description';
    BEGIN
        l_description := NULL;
        IF i_unit_measure IS NOT NULL
        THEN
        
            g_error := 'GET UNIT MEASURE DESCRIPTION';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            SELECT pk_translation.get_translation(i_lang, um.code_unit_measure) AS unit_mea_desc
              INTO l_description
              FROM unit_measure um
             WHERE um.id_unit_measure = i_unit_measure;
        END IF;
    
        RETURN l_description;
    
    EXCEPTION
        WHEN no_data_found THEN
            g_error := 'No unit of measurement was found with ID_UNIT_MEASURE = ' || to_char(i_unit_measure) || chr(10);
            g_error := g_error || 'Input arguments:';
            g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
            g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
            g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
            g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
            g_error := g_error || ' i_unit_measure = ' || coalesce(to_char(i_unit_measure), '<null>');
            pk_alertlog.log_error(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
            RETURN NULL;
            -- Unexpected error
        WHEN OTHERS THEN
            DECLARE
                l_error t_error_out;
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'GET_UNIT_MEASURE_DESCRIPTION',
                                                  l_error);
            
                RETURN NULL;
            END;
    END get_unit_measure_description;

    /********************************************************************************************
    * Returns info about all the available units of measurement
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param o_unit_measure_type         Unit of Measures types
    * @param o_unit_measure_subtype      Unit of Measures subtypes
    * @param o_unit_measure              Unit of Measures info
    
    * @param o_error                     Error message
    
    * @return                            True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5
    * @since   26-Jun-09
    **********************************************************************************************/
    FUNCTION get_all_unit_measures
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        o_unit_measure_type    OUT pk_types.cursor_type,
        o_unit_measure_subtype OUT pk_types.cursor_type,
        o_unit_measure         OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_inst_mrk market.id_market%TYPE;
    BEGIN
    
        --UOM Types
        g_error := 'OPEN o_unit_measure_type';
        OPEN o_unit_measure_type FOR
            SELECT uomt.id_unit_measure_type,
                   pk_translation.get_translation(i_lang, uomt.code_unit_measure_type) desc_unit_measure_type,
                   CAST(MULTISET (SELECT uoms.id_unit_measure_subtype
                           FROM unit_measure_subtype uoms
                          WHERE uoms.id_unit_measure_type = uomt.id_unit_measure_type) AS table_number) unit_measure_subtype_list
              FROM unit_measure_type uomt
             WHERE uomt.flg_available = pk_alert_constant.g_available
               AND EXISTS (SELECT 0
                      FROM unit_measure uom
                     WHERE uom.flg_available = pk_alert_constant.g_available
                       AND uom.id_unit_measure_type = uomt.id_unit_measure_type)
             ORDER BY desc_unit_measure_type;
    
        g_error := 'GET MARKET CONFIGURATION';
        SELECT id_market
          INTO l_id_inst_mrk
          FROM institution
         WHERE id_institution = i_prof.institution;
    
        -- UOM Subtypes
        g_error := 'OPEN o_unit_measure_subtype';
        OPEN o_unit_measure_subtype FOR
            SELECT x.id_unit_measure_subtype, x.id_unit_measure_type, x.desc_unit_measure_subtype, x.unit_measure_list
              FROM (SELECT uoms.id_unit_measure_subtype,
                           uoms.id_unit_measure_type,
                           pk_translation.get_translation(i_lang, uoms.code_unit_measure_subtype) desc_unit_measure_subtype,
                           CAST(MULTISET (SELECT uomg.id_unit_measure
                                   FROM unit_measure_group uomg
                                  WHERE uoms.id_unit_measure_subtype = uomg.id_unit_measure_subtype
                                    AND uoms.id_unit_measure_type = uomg.id_unit_measure_type
                                    AND (uomg.id_market = l_id_inst_mrk OR
                                        (uomg.id_market = 0 AND NOT EXISTS
                                         (SELECT 1
                                             FROM unit_measure_group x
                                            WHERE x.id_unit_measure_type = uomg.id_unit_measure_type
                                              AND x.id_unit_measure_subtype = uomg.id_unit_measure_subtype
                                              AND x.id_market = l_id_inst_mrk)))
                                  ORDER BY uomg.rank) AS table_number) unit_measure_list
                      FROM unit_measure_subtype uoms) x
             WHERE EXISTS (SELECT 1
                      FROM TABLE(x.unit_measure_list));
    
        --Units of measure
        g_error := 'OPEN o_unit_measure';
        OPEN o_unit_measure FOR
            SELECT t.id_unit_measure_type,
                   t.id_unit_measure,
                   t.desc_unit_measure,
                   coalesce(t.desc_unit_measure_abrv, t.desc_unit_measure) desc_unit_measure_abrv
              FROM (SELECT uom.id_unit_measure_type,
                           uom.id_unit_measure,
                           pk_translation.get_translation(i_lang, uom.code_unit_measure) desc_unit_measure,
                           pk_translation.get_translation(i_lang, uom.code_unit_measure_abrv) desc_unit_measure_abrv
                      FROM unit_measure uom
                     WHERE uom.flg_available = pk_alert_constant.g_available
                     ORDER BY id_unit_measure_type) t
             WHERE t.desc_unit_measure IS NOT NULL;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_ALL_UNIT_MEASURES');
                /* Open out cursors */
                pk_types.open_my_cursor(o_unit_measure_type);
                pk_types.open_my_cursor(o_unit_measure_subtype);
                pk_types.open_my_cursor(o_unit_measure);
            
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_all_unit_measures;

    FUNCTION get_unit_measure
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_unit_measure IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET UNIT MEASURE DESCRIPTION';
        OPEN o_list FOR
            SELECT um.id_unit_measure, pk_translation.get_translation(i_lang, um.code_unit_measure) AS des_unit_measure
              FROM unit_measure um
             WHERE um.id_unit_measure IN (SELECT /*+opt_estimate(table t rows=1)*/
                                           *
                                            FROM TABLE(i_unit_measure) t);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_UNIT_MEASURE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_unit_measure;

    ---- CMF
    FUNCTION get_dyn_only_umea_type
    (
        i_lang                 IN NUMBER,
        i_prof                 IN profissional,
        i_ds_component         IN NUMBER,
        i_unit_measure_subtype IN NUMBER
    ) RETURN t_tbl_dyn_umea IS
        tbl_return  t_tbl_dyn_umea;
        l_id_market NUMBER(24);
    BEGIN
    
        l_id_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        SELECT t_rec_dyn_umea(i_ds_component,
                              xsql.id_unit_measure,
                              xsql.id_unit_measure_subtype,
                              xsql.code_unit_measure,
                              pk_translation.get_translation(i_lang, xsql.code_unit_measure),
                              xsql.rank)
          BULK COLLECT
          INTO tbl_return
          FROM (SELECT um.id_unit_measure,
                       umg.id_unit_measure_subtype,
                       um.code_unit_measure,
                       umg.rank rank,
                       dense_rank() over(PARTITION BY id_market ORDER BY id_market DESC) partition_rank
                  FROM unit_measure_group umg
                  JOIN unit_measure um
                    ON um.id_unit_measure = umg.id_unit_measure
                 WHERE umg.id_unit_measure_subtype = i_unit_measure_subtype
                   AND umg.id_market IN (l_id_market, 0)
                   AND um.flg_available = 'Y'
                 ORDER BY umg.rank) xsql
         WHERE partition_rank = 1;
    
        RETURN tbl_return;
    
    END get_dyn_only_umea_type;
    ---- end done

    --

    FUNCTION get_dyn_only_umea
    (
        i_lang         IN NUMBER,
        i_ds_component IN NUMBER,
        i_unit_measure IN NUMBER
    ) RETURN t_tbl_dyn_umea IS
        tbl_return t_tbl_dyn_umea;
        --l_id_market NUMBER(24);
    BEGIN
    
        SELECT t_rec_dyn_umea(i_ds_component,
                              xsql.id_unit_measure,
                              xsql.id_unit_measure_subtype,
                              xsql.code_unit_measure,
                              pk_translation.get_translation(i_lang, xsql.code_unit_measure),
                              xsql.rank)
          BULK COLLECT
          INTO tbl_return
          FROM (SELECT um.id_unit_measure, NULL id_unit_measure_subtype, um.code_unit_measure, 0 rank
                  FROM unit_measure um
                 WHERE um.flg_available = 'Y'
                   AND um.id_unit_measure = i_unit_measure) xsql;
    
        RETURN tbl_return;
    
    END get_dyn_only_umea;
    -- end done
    FUNCTION get_umea_type_ds
    (
        i_lang                 IN NUMBER,
        i_prof                 IN profissional,
        i_unit_measure_subtype IN NUMBER,
        i_unit_measure         IN NUMBER,
        o_list                 OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market NUMBER(24);
    BEGIN
    
        l_id_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        OPEN o_list FOR
            SELECT xsql.id_unit_measure,
                   xsql.id_unit_measure_subtype,
                   xsql.code_unit_measure,
                   pk_translation.get_translation(i_lang, xsql.code_unit_measure) transl_unit_measure,
                   xsql.rank,
                   xmlelement("ADDITIONAL_INFO", xmlattributes(xsql.flg_default)).getclobval() addit_info
              FROM (SELECT um.id_unit_measure,
                           umg.id_unit_measure_subtype,
                           um.code_unit_measure,
                           umg.rank rank,
                           dense_rank() over(PARTITION BY id_market ORDER BY id_market DESC) partition_rank,
                           decode(um.id_unit_measure, i_unit_measure, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
                    
                      FROM unit_measure_group umg
                      JOIN unit_measure um
                        ON um.id_unit_measure = umg.id_unit_measure
                     WHERE umg.id_unit_measure_subtype = i_unit_measure_subtype
                       AND umg.id_market IN (l_id_market, 0)
                       AND um.flg_available = 'Y'
                     ORDER BY umg.rank) xsql
             WHERE partition_rank = 1
               AND pk_translation.get_translation(i_lang, xsql.code_unit_measure) IS NOT NULL
             ORDER BY xsql.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_package_owner, g_package_name, 'GET_UMEA_TYPE');
                /* Open out cursors */
                pk_types.open_my_cursor(o_list);
            
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
        
    END get_umea_type_ds;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_unit_measure;
/
