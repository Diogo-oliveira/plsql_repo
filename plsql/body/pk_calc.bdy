/*-- Last Change Revision: $Rev: 2016906 $*/
/*-- Last Change by: $Author: cristina.oliveira $*/
/*-- Date of last change: $Date: 2022-06-15 11:25:02 +0100 (qua, 15 jun 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_calc IS

    /**
    * Gets the number given the input string.
    *
    * @param i_number        The input number
    *
    * @return  The number represented by the string given as input.
    *
    * @author   Eduardo Lourenço
    * @version  2.5
    * @since    2008/03/02
    */
    FUNCTION get_number(i_number VARCHAR) RETURN NUMBER IS
    BEGIN
        g_error := 'get_number(' || i_number || ')';
        pk_alertlog.log_debug(g_error);
        RETURN to_number(translate(i_number, ',', '.'), g_fmt_num, g_nls);
    END;

    /**
    * Gets the number in a string expression given the input string.
    *
    * @param i_number        The input number
    *
    * @return  The number represented by the string given as input.
    *
    * @author   Eduardo Lourenço
    * @version  2.5
    * @since    2008/03/02
    */
    FUNCTION get_number_as_string(i_number VARCHAR) RETURN VARCHAR IS
    BEGIN
        g_error := 'get_number_as_string(' || i_number || ')';
        pk_alertlog.log_debug(g_error);
        RETURN to_char(to_number(translate(i_number, ',', '.'), g_fmt_num, g_nls), g_fmt_str, g_nls);
    END;

    /**
    * Gets the number in a string expression to be given to the user as output.
    *
    * @param i_prof    The professional
    * @param i_number  The input number
    * @param i_format  The format to be applied to the number.
    *
    * @return  The number represented by the string given as input.
    *
    * @author   Eduardo Lourenço
    * @version  2.5
    * @since    2008/03/02
    */
    FUNCTION get_number_to_show
    (
        i_prof   profissional,
        i_number VARCHAR,
        i_format calc_field_soft_inst.format%TYPE
    ) RETURN VARCHAR IS
        l_ret VARCHAR(100);
    BEGIN
        g_error := 'get_number_to_show(' || i_number || ')';
        pk_alertlog.log_debug(g_error);
        l_ret := TRIM(translate(to_char(to_number(translate(i_number, ',', '.'), g_fmt_num, g_nls),
                                        nvl(i_format, g_default_fmt)),
                                '.',
                                pk_sysconfig.get_config('DECIMAL_SYMBOL', i_prof)));
        RETURN l_ret;
    END;

    /**
    * Gets the calculator Id for the calculator name given as input
    *
    * @param i_prof          The professional record.
    * @param i_calc_name     The calculator name
    *
    * @return  The calculator Id.
    *
    * @author   Eduardo Lourenço
    * @version  2.5
    * @since    2008/03/02
    */
    FUNCTION get_calculator_id
    (
        i_prof      IN profissional,
        i_calc_name IN calculator.internal_name%TYPE
    ) RETURN NUMBER IS
        l_func_name     VARCHAR2(32) := 'GET_CALCULATOR_ID';
        l_id_calculator calculator.id_calculator%TYPE;
    BEGIN
        g_error := 'GET ID_CALCULATOR';
        pk_alertlog.log_debug(g_error);
        SELECT id_calculator
          INTO l_id_calculator
          FROM (SELECT c.id_calculator, csi.id_software, csi.id_institution
                  FROM calculator c
                 INNER JOIN calc_soft_inst csi
                    ON csi.id_software IN (0, i_prof.software)
                   AND csi.id_institution IN (0, i_prof.institution)
                 WHERE c.internal_name = i_calc_name
                   AND csi.flg_available = pk_alert_constant.g_yes
                 ORDER BY csi.id_institution DESC, csi.id_software DESC)
         WHERE rownum < 2;
        RETURN l_id_calculator;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.error_handling(i_func_proc_name => l_func_name,
                                               i_package_name   => g_package_name,
                                               i_package_error  => g_error,
                                               i_sql_error      => SQLERRM);
            RAISE g_exception;
    END get_calculator_id;

    /**
    * Gets the parameters for the calculator given as input
    *
    * @param i_lang      Language identifier.
    * @param i_prof      The professional record.
    * @param i_calc_name The calculator name
    *
    * @param o_cursor    The list of parameters of the calc.
    *
    * @param o_error     Message to be shown to the user.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.5
    * @since    2008/03/02
    */
    FUNCTION get_calc_details
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_calc_name IN calculator.internal_name%TYPE,
        o_cursor    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(32) := 'GET_CALC_DETAILS';
        l_id_calculator calculator.id_calculator%TYPE;
    BEGIN
        g_error := 'GET ID_CALCULATOR';
        pk_alertlog.log_debug(g_error);
        l_id_calculator := get_calculator_id(i_prof, i_calc_name);
    
        g_error := 'OPEN CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_cursor FOR
            SELECT c.id_calculator,
                   cf.id_calc_field,
                   pk_translation.get_translation(i_lang, cf.code_calc_field) desc_calc_field,
                   cf.flg_type,
                   cf.flg_mandatory,
                   um.id_unit_measure,
                   nvl(pk_translation.get_translation(i_lang, um.code_unit_measure_abrv),
                       pk_translation.get_translation(i_lang, um.code_unit_measure)) desc_unit_measure,
                   t.format
              FROM calculator c
              JOIN calc_field cf
                ON cf.id_calculator = c.id_calculator
              LEFT JOIN (SELECT id_calculator, id_calc_field, id_unit_measure, format
                           FROM (SELECT cfsi.id_calculator,
                                        cfsi.id_calc_field,
                                        cfsi.id_unit_measure,
                                        cfsi.format,
                                        row_number() over(PARTITION BY cfsi.id_calculator, cfsi.id_calc_field ORDER BY cfsi.id_institution DESC, cfsi.id_software DESC) rn
                                   FROM calc_field_soft_inst cfsi
                                  WHERE cfsi.id_institution IN (i_prof.institution, 0)
                                    AND cfsi.id_software IN (i_prof.software, 0))
                          WHERE rn = 1) t
                ON t.id_calculator = c.id_calculator
               AND t.id_calc_field = cf.id_calc_field
              LEFT JOIN unit_measure um
                ON um.id_unit_measure = t.id_unit_measure
             WHERE c.id_calculator = l_id_calculator
             ORDER BY cf.rank ASC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.error_handling(i_func_proc_name => l_func_name,
                                               i_package_name   => g_package_name,
                                               i_package_error  => g_error,
                                               i_sql_error      => SQLERRM);
            pk_types.open_my_cursor(o_cursor);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_calc_details;

    /**
    * Calculates the results using the fields and the unit measures given as parameters.
    *
    * @param i_lang            Language identifier.
    * @param i_prof            The professional record.
    * @param i_id_calculator   The calculator Id
    * @param i_id_fields_in    The list of input field Ids for the calculator
    * @param i_id_fields_out   The list of output field Ids for the calculator
    * @param i_id_unit_mea_in  The list of input unit measure Ids for the calculator
    * @param i_id_unit_mea_out The list of output unit measure Ids for the calculator
    * @param i_values          The values of the input fields to be calculated
    *
    * @param o_results         The list of values given as result of the calculation.
    *
    * @param o_error           Message to be shown to the user.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.5
    * @since    2008/03/02
    */
    FUNCTION get_calculation
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_calculator   IN calculator.id_calculator%TYPE,
        i_id_fields_in    IN table_number,
        i_id_fields_out   IN table_number,
        i_id_unit_mea_in  IN table_number,
        i_id_unit_mea_out IN table_number,
        i_format_out      IN table_varchar,
        i_values          IN table_varchar,
        o_results         OUT table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name       VARCHAR2(32) := 'GET_CALCULATION';
        l_formula         calculator.formula%TYPE;
        r_unit_conversion unit_measure_convert%ROWTYPE;
        r_calc_field      calc_field%ROWTYPE;
        l_values          table_varchar;
        l_numbers         table_number;
        l_record          table_varchar := table_varchar();
        c_cursor          pk_types.cursor_type;
        l_id_calc_field   calc_field.id_calc_field%TYPE;
        CURSOR c_calc_field IS
            SELECT cf.*
              FROM calc_field cf
             WHERE cf.id_calc_field = l_id_calc_field;
    
        l_id_unit_measure unit_measure.id_unit_measure%TYPE;
        l_id_unit_orig    unit_measure.id_unit_measure%TYPE;
    
        CURSOR c_unit_conversion IS
            SELECT umc.*
              FROM unit_measure_convert umc
             WHERE umc.id_unit_measure1 = l_id_unit_measure
               AND umc.id_unit_measure2 = l_id_unit_orig;
    
    BEGIN
    
        g_error := 'GET FORMULA';
        pk_alertlog.log_debug(g_error);
        SELECT c.formula
          INTO l_formula
          FROM calculator c
         WHERE c.id_calculator = i_id_calculator;
    
        l_values := table_varchar();
        l_values.extend(i_values.count);
        l_numbers := table_number();
        l_numbers.extend(i_values.count);
        FOR i IN 1 .. i_values.count
        LOOP
            BEGIN
                l_numbers(i) := get_number(i_values(i));
                l_values(i) := i_values(i);
            EXCEPTION
                WHEN OTHERS THEN
                    l_numbers(i) := NULL;
                    l_values(i) := i_values(i);
            END;
            l_id_calc_field := i_id_fields_in(i);
            g_error         := 'OPEN c_calc_field - l_id_calc_field = ' || l_id_calc_field;
            pk_alertlog.log_debug(g_error);
            OPEN c_calc_field;
            FETCH c_calc_field
                INTO r_calc_field;
            CLOSE c_calc_field;
        
            IF i_id_unit_mea_in(i) != r_calc_field.id_unit_mea_orig
            THEN
                g_error := 'i_id_unit_mea_in(i) != r_calc_field.id_unit_mea_orig - ' || i_id_unit_mea_in(i) || ' != ' ||
                           r_calc_field.id_unit_mea_orig || '. Will convert input values.';
                pk_alertlog.log_debug(g_error);
                l_id_unit_measure := i_id_unit_mea_in(i);
                l_id_unit_orig    := r_calc_field.id_unit_mea_orig;
                g_error           := 'OPEN c_unit_conversion - l_id_unit_measure = ' || l_id_unit_measure ||
                                     '; l_id_unit_orig = ' || l_id_unit_orig;
                pk_alertlog.log_debug(g_error);
                OPEN c_unit_conversion;
                FETCH c_unit_conversion
                    INTO r_unit_conversion;
                CLOSE c_unit_conversion;
                IF r_unit_conversion.formula IS NOT NULL
                THEN
                    IF l_numbers(i) IS NOT NULL
                    THEN
                        g_error := 'EXECUTE IMMEDIATE - formula = ' || r_unit_conversion.formula || ' using ' ||
                                   l_numbers(i);
                        pk_alertlog.log_debug(g_error);
                        EXECUTE IMMEDIATE r_unit_conversion.formula
                            INTO l_values(i)
                            USING l_numbers(i);
                    
                    ELSE
                        g_error := 'EXECUTE IMMEDIATE - formula = ' || r_unit_conversion.formula || ' using ' ||
                                   l_values(i);
                        pk_alertlog.log_debug(g_error);
                        EXECUTE IMMEDIATE r_unit_conversion.formula
                            INTO l_values(i)
                            USING l_values(i);
                    
                    END IF;
                END IF;
            END IF;
            l_values(i) := get_number_as_string(l_values(i));
            l_numbers(i) := NULL;
            g_error := 'l_values(' || i || ') is now ' || l_values(i);
            pk_alertlog.log_debug(g_error);
        
            g_error := 'Before replace - formula = ' || l_formula;
            pk_alertlog.log_debug(g_error);
            l_formula := REPLACE(l_formula, ':' || i, l_values(i));
            g_error   := 'After replace :' || i || ' by ' || l_values(i) || ' - formula = ' || l_formula;
            pk_alertlog.log_debug(g_error);
        END LOOP;
    
        g_error := 'OPEN c_cursor';
        pk_alertlog.log_debug(g_error);
        OPEN c_cursor FOR l_formula;
        LOOP
            FETCH c_cursor BULK COLLECT
                INTO l_record;
        
            EXIT WHEN c_cursor%NOTFOUND;
        END LOOP;
        CLOSE c_cursor;
        o_results := table_varchar();
        o_results.extend(l_record.count);
        FOR i IN 1 .. l_record.count
        LOOP
            l_id_calc_field := i_id_fields_out(i);
            g_error         := 'OPEN c_calc_field - l_id_calc_field = ' || l_id_calc_field;
            pk_alertlog.log_debug(g_error);
            OPEN c_calc_field;
            FETCH c_calc_field
                INTO r_calc_field;
            CLOSE c_calc_field;
        
            IF r_calc_field.id_unit_mea_orig IS NOT NULL
               AND i_id_unit_mea_out IS NOT NULL
               AND i_id_unit_mea_out(i) IS NOT NULL
               AND i_id_unit_mea_out(i) != r_calc_field.id_unit_mea_orig
            THEN
                l_id_unit_measure := i_id_unit_mea_out(i);
                l_id_unit_orig    := r_calc_field.id_unit_mea_orig;
                g_error           := 'OPEN c_unit_conversion - l_id_unit_measure = ' || l_id_unit_measure ||
                                     '; l_id_unit_orig = ' || l_id_unit_orig;
                pk_alertlog.log_debug(g_error);
                OPEN c_unit_conversion;
                FETCH c_unit_conversion
                    INTO r_unit_conversion;
                CLOSE c_unit_conversion;
            
                IF r_unit_conversion.formula IS NOT NULL
                THEN
                    g_error := 'EXECUTE IMMEDIATE - formula = ' || r_unit_conversion.formula || ' using ' ||
                               get_number(l_record(i));
                    pk_alertlog.log_debug(g_error);
                    EXECUTE IMMEDIATE r_unit_conversion.formula
                        INTO o_results(i)
                        USING get_number(l_record(i));
                    g_error := 'o_results(' || i || ') = ' || o_results(i);
                    pk_alertlog.log_debug(g_error);
                    o_results(i) := round(o_results(i), r_unit_conversion.decimals);
                ELSE
                    BEGIN
                        o_results(i) := get_number_to_show(i_prof, l_record(i), i_format_out(i));
                    EXCEPTION
                        WHEN OTHERS THEN
                            o_results(i) := l_record(i);
                    END;
                END IF;
            ELSE
                BEGIN
                    o_results(i) := get_number_to_show(i_prof, l_record(i), i_format_out(i));
                EXCEPTION
                    WHEN OTHERS THEN
                        o_results(i) := l_record(i);
                END;
            END IF;
        END LOOP;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_calculation;

    /**
    * Calculates the results using the fields and the unit measures given as parameters.
    *
    * @param i_lang            Language identifier.
    * @param i_prof            The professional record.
    * @param i_id_calculator   The calculator Id
    * @param i_id_fields_in    The list of input field Ids for the calculator
    * @param i_id_fields_out   The list of output field Ids for the calculator
    * @param i_id_unit_mea_in  The list of input unit measure Ids for the calculator
    * @param i_id_unit_mea_out The list of output unit measure Ids for the calculator
    * @param i_format_out      The list of formats to be applied to the output results
    * @param i_values          The values of the input fields to be calculated
    *
    * @return  The list of values given as result of the calculation.
    *
    * @author   Eduardo Lourenço
    * @version  2.5
    * @since    2008/03/02
    */
    FUNCTION get_calculation
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_calculator   IN calculator.id_calculator%TYPE,
        i_id_fields_in    IN table_number,
        i_id_fields_out   IN table_number,
        i_id_unit_mea_in  IN table_number,
        i_id_unit_mea_out IN table_number,
        i_format_out      IN table_varchar,
        i_values          IN table_varchar
    ) RETURN table_varchar IS
        l_values    table_varchar;
        l_func_name VARCHAR2(32) := 'GET_CALCULATION';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL get_calculation';
        pk_alertlog.log_debug(g_error);
        IF get_calculation(i_lang            => i_lang,
                           i_prof            => i_prof,
                           i_id_calculator   => i_id_calculator,
                           i_id_fields_in    => i_id_fields_in,
                           i_id_fields_out   => i_id_fields_out,
                           i_id_unit_mea_in  => i_id_unit_mea_in,
                           i_id_unit_mea_out => i_id_unit_mea_out,
                           i_format_out      => i_format_out,
                           i_values          => i_values,
                           o_results         => l_values,
                           o_error           => l_error)
        THEN
            RETURN l_values;
        ELSE
            RAISE g_exception;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              l_error);
    END get_calculation;

    /**
    * Calculates the results using the fields and the unit measures given as parameters.
    *
    * @param i_lang            Language identifier.
    * @param i_prof            The professional record.
    * @param i_id_calculator   The calculator Id
    * @param i_id_fields_in    The list of input field Ids for the calculator
    * @param i_id_field_out    The output field Id for the calculator
    * @param i_id_unit_mea_in  The list of input unit measure Ids for the calculator
    * @param i_id_unit_mea_out The list of output unit measure Ids for the calculator
    * @param i_format_out      The list of formats to be applied to the output results
    * @param i_values          The values of the input fields to be calculated
    *
    * @return  The list of values given as result of the calculation.
    *
    * @author   Eduardo Lourenço
    * @version  2.5
    * @since    2008/03/02
    */
    FUNCTION get_calculation
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_calculator   IN calculator.id_calculator%TYPE,
        i_id_fields_in    IN table_number,
        i_id_field_out    IN calc_field.id_calc_field%TYPE,
        i_id_unit_mea_in  IN table_number,
        i_id_unit_mea_out IN NUMBER,
        i_format_out      IN calc_field_soft_inst.format%TYPE,
        i_values          IN table_varchar
    ) RETURN VARCHAR IS
        l_values    table_varchar;
        l_func_name VARCHAR2(32) := 'GET_CALCULATION';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL get_calculation';
        pk_alertlog.log_debug(g_error);
        IF get_calculation(i_lang            => i_lang,
                           i_prof            => i_prof,
                           i_id_calculator   => i_id_calculator,
                           i_id_fields_in    => i_id_fields_in,
                           i_id_fields_out   => table_number(i_id_field_out),
                           i_id_unit_mea_in  => i_id_unit_mea_in,
                           i_id_unit_mea_out => table_number(i_id_unit_mea_out),
                           i_format_out      => table_varchar(i_format_out),
                           i_values          => i_values,
                           o_results         => l_values,
                           o_error           => l_error)
        THEN
            RETURN l_values(1);
        ELSE
            RAISE g_exception;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              l_error);
    END get_calculation;

    /**
    * Calculates the Body Mass Index (BMI) and Body Surface Area (BSA) given the weight and the height as parameters.
    *
    * @param i_lang            Language identifier.
    * @param i_prof            The professional record.
    * @param i_weight          The weight
    * @param i_weight_um       The unit measure assigned to the weight
    * @param i_height          The height
    * @param i_height_um       The unit measure assigned to the height
    * @param i_calc_name       Calculator internal name
    *
    * @return  the BMI or BSA.
    *
    * @author   Eduardo Lourenço
    * @version  2.5
    * @since    2008/03/02
    */
    FUNCTION get_calc_internal
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_weight    IN VARCHAR2,
        i_weight_um unit_measure.id_unit_measure%TYPE,
        i_height    IN VARCHAR2,
        i_height_um unit_measure.id_unit_measure%TYPE,
        i_calc_name IN calculator.internal_name%TYPE
    ) RETURN VARCHAR IS
        l_func_name VARCHAR2(32) := 'GET_CALC_INTERNAL';
        c_cursor    pk_types.cursor_type;
        TYPE t_calc IS RECORD(
            id_calculator     calculator.id_calculator%TYPE,
            id_calc_field     calc_field.id_calc_field%TYPE,
            desc_calc_field   VARCHAR(4000),
            flg_type          calc_field.flg_type%TYPE,
            flg_mandatory     calc_field.flg_mandatory%TYPE,
            id_unit_measure   unit_measure.id_unit_measure%TYPE,
            desc_unit_measure VARCHAR(4000),
            format            calc_field_soft_inst.format%TYPE);
    
        TYPE t_t_calc IS TABLE OF t_calc;
        r_calc t_t_calc;
    
        l_results table_varchar;
        l_error   t_error_out;
    BEGIN
        g_error := 'CALL get_calc_details';
        pk_alertlog.log_debug(g_error);
        IF get_calc_details(i_lang      => i_lang,
                            i_prof      => i_prof,
                            i_calc_name => i_calc_name,
                            o_cursor    => c_cursor,
                            o_error     => l_error)
        THEN
            g_error := 'fetch c_cursor';
            pk_alertlog.log_debug(g_error);
            FETCH c_cursor BULK COLLECT
                INTO r_calc;
            CLOSE c_cursor;
        ELSE
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL get_calculation';
        pk_alertlog.log_debug(g_error);
        IF get_calculation(i_lang            => i_lang,
                           i_prof            => i_prof,
                           i_id_calculator   => r_calc(1).id_calculator,
                           i_id_fields_in    => table_number(r_calc(1).id_calc_field, r_calc(2).id_calc_field),
                           i_id_fields_out   => table_number(r_calc(3).id_calc_field),
                           i_id_unit_mea_in  => table_number(i_weight_um, i_height_um),
                           i_id_unit_mea_out => table_number(r_calc(3).id_unit_measure),
                           i_format_out      => table_varchar(r_calc(3).format),
                           i_values          => table_varchar(i_weight, i_height),
                           o_results         => l_results,
                           o_error           => l_error)
        THEN
            RETURN l_results(1);
        ELSE
            RAISE g_exception;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.error_handling(i_func_proc_name => l_func_name,
                                               i_package_name   => g_package_name,
                                               i_package_error  => g_error,
                                               i_sql_error      => SQLERRM);
            RAISE g_exception;
    END get_calc_internal;

    /************************************************************************************************************
    * Calculates the Body Mass Index (BMI) given the weight and the height as parameters.
    *
    * @param i_lang            Language identifier.
    * @param i_prof            The professional record.
    * @param i_weight          The weight
    * @param i_weight_um       The unit measure assigned to the weight
    * @param i_height          The height
    * @param i_height_um       The unit measure assigned to the height
    *
    * @return                  Returns BMI value.
    * 
    * @author                  Luís Maia
    * @version                 2.6.1
    * @since                   02-Jan-2012
    ************************************************************************************************************/
    FUNCTION get_bmi
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_weight    IN VARCHAR2,
        i_weight_um IN unit_measure.id_unit_measure%TYPE,
        i_height    IN VARCHAR2,
        i_height_um IN unit_measure.id_unit_measure%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        g_error := 'CALL get_bmi_internal';
        pk_alertlog.log_debug(g_error);
        RETURN get_calc_internal(i_lang      => i_lang,
                                 i_prof      => i_prof,
                                 i_weight    => i_weight,
                                 i_weight_um => i_weight_um,
                                 i_height    => i_height,
                                 i_height_um => i_height_um,
                                 i_calc_name => g_calc_name_bmi);
    END get_bmi;

    /************************************************************************************************************
    * Calculates the Body Surface Area (BSA) given the weight and the height as parameters.
    *
    * @param i_lang            Language identifier.
    * @param i_prof            The professional record.
    * @param i_weight          The weight
    * @param i_weight_um       The unit measure assigned to the weight
    * @param i_height          The height
    * @param i_height_um       The unit measure assigned to the height
    *
    * @return                  Returns BSA value.
    * 
    * @author                  Luís Maia
    * @version                 2.6.1
    * @since                   02-Jan-2012
    ************************************************************************************************************/
    FUNCTION get_bsa
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_weight    IN VARCHAR2,
        i_weight_um IN unit_measure.id_unit_measure%TYPE,
        i_height    IN VARCHAR2,
        i_height_um IN unit_measure.id_unit_measure%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        g_error := 'CALL get_bmi_internal';
        pk_alertlog.log_debug(g_error);
        RETURN get_calc_internal(i_lang      => i_lang,
                                 i_prof      => i_prof,
                                 i_weight    => i_weight,
                                 i_weight_um => i_weight_um,
                                 i_height    => i_height,
                                 i_height_um => i_height_um,
                                 i_calc_name => g_calc_name_bsa);
    END get_bsa;

    /**********************************************************************************************
    * Obter lista dos profissionais da instituição
    *
    * @param i_lang                   Language id
    * @param i_prof                   professional, software and institution ids
    * @param i_patient                patient id
    * @param o_lst_imc                Last active values of Weight and Height Vital Signs
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Luís Maia
    * @since                          29-Set-2011
    **********************************************************************************************/
    FUNCTION get_pat_lst_imc_values
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN vital_signs_ea.id_patient%TYPE,
        o_lst_imc OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_PAT_LST_IMC_VALUES';
    BEGIN
        IF NOT pk_vital_sign.get_pat_lst_imc_values(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_patient => i_patient,
                                                    o_lst_imc => o_lst_imc,
                                                    o_error   => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.error_handling(i_func_proc_name => l_func_name,
                                               i_package_name   => g_package_name,
                                               i_package_error  => g_error,
                                               i_sql_error      => SQLERRM);
            RAISE g_exception;
    END get_pat_lst_imc_values;

BEGIN
    -- Log initialization.
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

END pk_calc;
/
