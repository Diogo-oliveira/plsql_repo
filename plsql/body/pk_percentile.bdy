/*-- Last Change Revision: $Rev: 2027477 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:20 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_percentile IS

    g_package_owner VARCHAR2(30 CHAR);
    g_package_name  VARCHAR2(30 CHAR);
    g_error         VARCHAR2(1000 CHAR);
    g_exception EXCEPTION;

    /***************************************************************************************
    * this function is the entry point to calculate percentile VS based on a read VS
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Pedro Teixeira
    * @version    2.7
    * @since      28/09/2017
    ***************************************************************************************/
    FUNCTION set_percentile_vs
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE DEFAULT NULL,
        i_episode            IN vital_sign_read.id_episode%TYPE DEFAULT NULL,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'set_percentile_vs';
    
        l_id_vital_sign      vital_sign_read.id_vital_sign%TYPE;
        l_vs_value           vital_sign_read.value%TYPE;
        l_vs_dt_read         vital_sign_read.dt_vital_sign_read_tstz%TYPE;
        l_vs_id_unit_measure vital_sign_read.id_unit_measure%TYPE;
        i_vs_id_patient      vital_sign_read.id_patient%TYPE;
        i_vs_id_episode      vital_sign_read.id_episode%TYPE;
    
        l_id_percentile_vs   vital_sign.id_vital_sign%TYPE;
        l_high_percentile    graphic_line.line_value%TYPE;
        l_low_percentile     graphic_line.line_value%TYPE;
        l_nearest_percentile graphic_line.line_value%TYPE;
    BEGIN
        -----------------------------------------------------------------
        -- obtain read vital sign data
        SELECT vsr.id_vital_sign,
               vsr.value,
               vsr.dt_vital_sign_read_tstz,
               vsr.id_unit_measure,
               nvl(i_patient, vsr.id_patient),
               nvl(i_episode, vsr.id_episode)
          INTO l_id_vital_sign, l_vs_value, l_vs_dt_read, l_vs_id_unit_measure, i_vs_id_patient, i_vs_id_episode
          FROM vital_sign_read vsr
         WHERE vsr.id_vital_sign_read = i_id_vital_sign_read;
    
        -----------------------------------------------------------------
        -- set percentile for read vital sign
        IF NOT set_percentile_vs(i_lang               => i_lang,
                                 i_prof               => i_prof,
                                 i_patient            => i_vs_id_patient,
                                 i_episode            => i_vs_id_episode,
                                 i_id_vital_sign      => l_id_vital_sign,
                                 i_vs_value           => l_vs_value,
                                 i_vs_id_unit_measure => l_vs_id_unit_measure,
                                 i_vs_dt_read         => l_vs_dt_read,
                                 o_id_percentile_vs   => l_id_percentile_vs,
                                 o_high_percentile    => l_high_percentile,
                                 o_low_percentile     => l_low_percentile,
                                 o_nearest_percentile => l_nearest_percentile,
                                 o_error              => o_error)
        THEN
            RAISE g_exception;
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
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN FALSE;
    END set_percentile_vs;

    /***************************************************************************************
    * this function is the entry point to calculate percentile VS based on id VS, date VS, value VS, etc
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Pedro Teixeira
    * @version    2.7
    * @since      28/09/2017
    ***************************************************************************************/
    FUNCTION set_percentile_vs
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN vital_sign_read.id_episode%TYPE,
        i_id_vital_sign      IN vital_sign.id_vital_sign%TYPE,
        i_vs_value           IN vital_sign_read.value%TYPE,
        i_vs_id_unit_measure IN vital_sign_read.id_unit_measure%TYPE,
        i_vs_dt_read         IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        o_id_percentile_vs   OUT vital_sign.id_vital_sign%TYPE,
        o_high_percentile    OUT graphic_line.line_value%TYPE,
        o_low_percentile     OUT graphic_line.line_value%TYPE,
        o_nearest_percentile OUT graphic_line.line_value%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'DELETE_PERCENTILE_VS';
    
        l_id_percentile_vs      vital_sign.id_vital_sign%TYPE;
        l_id_percentile_graphic graphic.id_graphic%TYPE;
        l_graph_id_unit_measure graphic.id_unit_measure%TYPE;
        l_pat_age               NUMBER;
        l_vs_value              vital_sign_read.value%TYPE;
    
        l_high_percentile    graphic_line.line_value%TYPE;
        l_low_percentile     graphic_line.line_value%TYPE;
        l_nearest_percentile graphic_line.line_value%TYPE;
    
        l_vital_sign_read_out table_number := table_number();
        l_dt_registry_out     VARCHAR2(100 CHAR);
    BEGIN
        -----------------------------------------------------------------
        -- only possibility is to have more than one weight associated (related) with one percentile VS
        IF NOT get_relation_percentile_vs(i_lang              => i_lang,
                                          i_prof              => i_prof,
                                          i_id_vital_sign     => i_id_vital_sign,
                                          o_id_vital_sign_rel => l_id_percentile_vs,
                                          o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_id_percentile_vs IS NULL
        THEN
            RETURN TRUE;
        END IF;
    
        -----------------------------------------------------------------
        -- using the registered VS ID and patient age (calculate internally using date birth and date when VS was read),
        -- determine wich graphic is the correct one
        IF NOT get_percentile_graphic(i_lang                  => i_lang,
                                      i_prof                  => i_prof,
                                      i_patient               => i_patient,
                                      i_id_vital_sign         => i_id_vital_sign,
                                      i_vs_dt_read            => i_vs_dt_read,
                                      o_id_graphic            => l_id_percentile_graphic,
                                      o_graph_id_unit_measure => l_graph_id_unit_measure,
                                      o_pat_age               => l_pat_age,
                                      o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_id_percentile_graphic IS NULL
        THEN
            RETURN TRUE;
        END IF;
    
        -----------------------------------------------------------------
        -- convert VS unit_measure into graphic unit_measure in order to be able to calculate the percentile
        l_vs_value := pk_unit_measure.get_unit_mea_conversion(i_value         => i_vs_value,
                                                              i_unit_meas     => i_vs_id_unit_measure,
                                                              i_unit_meas_def => l_graph_id_unit_measure);
    
        IF l_vs_value IS NULL
        THEN
            RETURN TRUE;
        END IF;
    
        -----------------------------------------------------------------
        -- calculate percentile based in age (as X axis) and registered VS value (weight, height, etc...) (as Y axis)
        IF NOT calculate_percentile(i_lang               => i_lang,
                                    i_id_graphic         => l_id_percentile_graphic,
                                    i_input_x_value      => l_pat_age,
                                    i_input_y_value      => l_vs_value,
                                    o_high_percentile    => l_high_percentile,
                                    o_low_percentile     => l_low_percentile,
                                    o_nearest_percentile => l_nearest_percentile,
                                    o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -----------------------------------------------------------------
        -- save percentile VS
        IF NOT pk_vital_sign.set_epis_vital_sign(i_lang               => i_lang,
                                                 i_episode            => i_episode,
                                                 i_prof               => i_prof,
                                                 i_pat                => i_patient,
                                                 i_vs_id              => table_number(l_id_percentile_vs),
                                                 i_vs_val             => table_number(l_nearest_percentile),
                                                 i_id_monit           => NULL,
                                                 i_unit_meas          => table_number(NULL),
                                                 i_vs_scales_elements => table_number(NULL),
                                                 i_notes              => NULL,
                                                 i_prof_cat_type      => NULL, -- calculated internally based on i_prof
                                                 i_dt_vs_read         => table_varchar(pk_date_utils.date_send_tsz(i_lang,
                                                                                                                   i_vs_dt_read,
                                                                                                                   i_prof)), -- necessary to pass date string
                                                 i_epis_triage        => NULL,
                                                 i_unit_meas_convert  => table_number(NULL),
                                                 i_vs_val_high        => table_number(l_high_percentile),
                                                 i_vs_val_low         => table_number(l_low_percentile),
                                                 o_vital_sign_read    => l_vital_sign_read_out,
                                                 o_dt_registry        => l_dt_registry_out,
                                                 o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        o_id_percentile_vs   := l_id_percentile_vs;
        o_high_percentile    := l_high_percentile;
        o_low_percentile     := l_low_percentile;
        o_nearest_percentile := l_nearest_percentile;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
          
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            
            RETURN FALSE;
    END set_percentile_vs;

    /***************************************************************************************
    * this function is the entry point to cancel a percentile VS based on a canceled VS
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Pedro Teixeira
    * @version    2.7
    * @since      28/09/2017
    ***************************************************************************************/
    FUNCTION cancel_percentile_vs
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN vital_sign_read.id_episode%TYPE DEFAULT NULL,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'cancel_percentile_vs';
    
        l_id_vital_sign       vital_sign_read.id_vital_sign%TYPE;
        l_vs_id_episode       vital_sign_read.id_episode%TYPE;
        l_vs_dt_read          vital_sign_read.dt_vital_sign_read_tstz%TYPE;
        l_vs_id_cancel_reason vital_sign_read.id_cancel_reason%TYPE;
        l_vs_notes_cancel     vital_sign_read.notes_cancel%TYPE;
    BEGIN
        -----------------------------------------------------------------
        -- obtain read vital sign data
        SELECT vsr.id_vital_sign,
               nvl(i_episode, vsr.id_episode),
               vsr.dt_vital_sign_read_tstz,
               vsr.id_cancel_reason,
               vsr.notes_cancel
          INTO l_id_vital_sign, l_vs_id_episode, l_vs_dt_read, l_vs_id_cancel_reason, l_vs_notes_cancel
          FROM vital_sign_read vsr
         WHERE vsr.id_vital_sign_read = i_id_vital_sign_read;
    
        -----------------------------------------------------------------
        -- cancel percentile for read vital sign
        IF NOT cancel_percentile_vs(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_episode          => l_vs_id_episode,
                                    i_id_vital_sign    => l_id_vital_sign,
                                    i_vs_dt_read       => l_vs_dt_read,
                                    i_id_cancel_reason => l_vs_id_cancel_reason,
                                    i_notes_cancel     => l_vs_notes_cancel,
                                    o_error            => o_error)
        THEN
            RAISE g_exception;
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
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN FALSE;
    END cancel_percentile_vs;

    /***************************************************************************************
    * this function is the entry point to cancel a percentile VS based on id VS, date VS, etc
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Pedro Teixeira
    * @version    2.7
    * @since      28/09/2017
    ***************************************************************************************/
    FUNCTION cancel_percentile_vs
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN vital_sign_read.id_episode%TYPE,
        i_id_vital_sign    IN vital_sign.id_vital_sign%TYPE,
        i_vs_dt_read       IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE DEFAULT NULL,
        i_notes_cancel     IN vital_sign_read.notes_cancel%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'cancel_percentile_vs';
    
        l_id_percentile_vs   vital_sign.id_vital_sign%TYPE;
        l_id_vital_sign_read vital_sign_read.id_vital_sign_read%TYPE;
    BEGIN
        -----------------------------------------------------------------
        -- determine associated percentile_vs (percentile Vital Sign associated with registered/deleted VS)
        IF NOT get_relation_percentile_vs(i_lang              => i_lang,
                                          i_prof              => i_prof,
                                          i_id_vital_sign     => i_id_vital_sign,
                                          o_id_vital_sign_rel => l_id_percentile_vs,
                                          o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_id_percentile_vs IS NULL
        THEN
            RETURN TRUE;
        END IF;
    
        -----------------------------------------------------------------
        BEGIN
            -- retrieves percentile VS through date of registry (same as BMI and BSA)
            SELECT vsr.id_vital_sign_read
              INTO l_id_vital_sign_read
              FROM vital_sign_read vsr
             WHERE vsr.dt_vital_sign_read_tstz = i_vs_dt_read
               AND vsr.id_vital_sign = l_id_percentile_vs
               AND vsr.flg_state != pk_vital_sign.c_flg_status_cancelled;
        EXCEPTION
            WHEN no_data_found THEN
                -- if no data was found, means no record necessary to be deleted
                RETURN TRUE;
        END;
    
        -----------------------------------------------------------------
        -- cancel percentile VS
        IF NOT pk_vital_sign_core.cancel_epis_vs_read(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_episode            => i_episode,
                                                      i_id_vital_sign_read => l_id_vital_sign_read,
                                                      i_id_cancel_reason   => i_id_cancel_reason,
                                                      i_notes              => i_notes_cancel,
                                                      o_error              => o_error)
        THEN
            RAISE g_exception;
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
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN FALSE;
    END cancel_percentile_vs;

    /***************************************************************************************
    * obtain the percentile VS based on the read VS
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Pedro Teixeira
    * @version    2.7
    * @since      28/09/2017
    ***************************************************************************************/
    FUNCTION get_relation_percentile_vs
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_vital_sign     IN vital_sign.id_vital_sign%TYPE,
        o_id_vital_sign_rel OUT vital_sign.id_vital_sign%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_RELATION_PERCENTILE_VS';
    
    BEGIN
        -----------------------------------------------------------------
        -- table vital_sign_relation has the necessary relations
        -- between Vital Signs and the Percentile of those Vital Signs
        SELECT vsr.id_vital_sign_detail
          INTO o_id_vital_sign_rel
          FROM vital_sign_relation vsr
         WHERE vsr.id_vital_sign_parent = i_id_vital_sign
           AND vsr.relation_domain = pk_alert_constant.g_vs_rel_percentile
           AND rownum = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN FALSE;
    END get_relation_percentile_vs;

    /***************************************************************************************
    * using the registered VS ID and patient age (calculate internally using date birth and date when VS was read),
    * determine wich graphic is the correct one
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Pedro Teixeira
    * @version    2.7
    * @since      28/09/2017
    ***************************************************************************************/
    FUNCTION get_percentile_graphic
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_id_vital_sign         IN vital_sign.id_vital_sign%TYPE,
        i_vs_dt_read            IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        o_id_graphic            OUT graphic.id_graphic%TYPE,
        o_graph_id_unit_measure OUT graphic.id_unit_measure%TYPE,
        o_pat_age               OUT NUMBER,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_PERCENTILE_GRAPHIC';
    
        l_graph_list table_number := table_number();
    
        l_pat_age_years  NUMBER;
        l_pat_age_months NUMBER;
    
        -----------------------------------------------------------------
        FUNCTION get_pat_age_years(l_graph_type IN graphic.flg_x_axis_type%TYPE) RETURN NUMBER IS
            l_dt_birth patient.dt_birth%TYPE;
            l_age      patient.age%TYPE;
            l_age_dt   vital_sign_read.dt_vital_sign_read_tstz%TYPE;
        
            l_pat_age_years NUMBER;
        BEGIN
            ----------------------------------------
            SELECT p.dt_birth, p.age
              INTO l_dt_birth, l_age
              FROM patient p
             WHERE p.id_patient = i_patient;
        
            ----------------------------------------        
            IF l_dt_birth IS NULL
            THEN
                l_age_dt := pk_date_utils.add_to_ltstz(i_timestamp => current_timestamp,
                                                      i_amount    => nvl(l_age, 0) * -1,
                                                      i_unit      => 'YEAR');
            ELSE
                l_age_dt := pk_date_utils.convert_dt_tsz(i_lang, i_prof, l_dt_birth); --CAST(l_dt_birth AS TIMESTAMP WITH LOCAL TIME ZONE);
            END IF;
        
            ----------------------------------------
            SELECT pk_vital_sign.get_graph_x_value(i_vs_dt_read, l_age_dt, l_graph_type) --g_graph_year)
              INTO l_pat_age_years
              FROM dual;
        
            RETURN l_pat_age_years;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
        END;
    BEGIN
        -----------------------------------------------------------------
        -- get list of all patient possible graphics
        IF NOT pk_vital_sign.get_graphics_by_patient(i_lang    => i_lang,
                                                     i_prof    => i_prof,
                                                     i_patient => i_patient,
                                                     o_graphs  => l_graph_list,
                                                     o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -----------------------------------------------------------------
        IF nvl(cardinality(l_graph_list), 0) > 0
        THEN
            -----------------------------------------------------------------
            -- get patient age in Years and Months, this will serve as X Axis selector
            l_pat_age_years  := nvl(get_pat_age_years(g_graph_year),
                                    pk_patient.get_pat_age(i_lang        => i_lang,
                                                           i_dt_birth    => NULL,
                                                           i_dt_deceased => NULL,
                                                           i_age         => NULL,
                                                           i_age_format  => 'YEARS',
                                                           i_patient     => i_patient));
            l_pat_age_months := nvl(get_pat_age_years(g_graph_month),
                                    pk_patient.get_pat_age(i_lang        => i_lang,
                                                           i_dt_birth    => NULL,
                                                           i_dt_deceased => NULL,
                                                           i_age         => NULL,
                                                           i_age_format  => 'MONTHS',
                                                           i_patient     => i_patient));
        
            -----------------------------------------------------------------
            -- obtaing correct graphic from list obtained above, based on patient age
            BEGIN
                SELECT *
                  INTO o_id_graphic, o_graph_id_unit_measure, o_pat_age
                  FROM (SELECT g.id_graphic,
                               g.id_unit_measure,
                               decode(g.flg_x_axis_type,
                                      g_graph_year,
                                      l_pat_age_years,
                                      g_graph_month,
                                      l_pat_age_months,
                                      NULL)
                          FROM graphic g
                         WHERE g.id_graphic IN (SELECT column_value
                                                  FROM TABLE(l_graph_list))
                           AND g.id_related_object = i_id_vital_sign
                           AND ((g.flg_x_axis_type = g_graph_year AND g.x_axis_start <= l_pat_age_years AND
                               g.x_axis_end > l_pat_age_years) OR
                               (g.flg_x_axis_type = g_graph_month AND g.x_axis_start <= l_pat_age_months AND
                               g.x_axis_end > l_pat_age_months))
                         ORDER BY decode(g.flg_x_axis_type, g_graph_year, 1, g_graph_month, 0, 1))
                 WHERE rownum = 1;
            
            EXCEPTION
                WHEN no_data_found THEN
                    o_id_graphic := NULL;
                    o_pat_age    := NULL;
            END;
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
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN FALSE;
    END get_percentile_graphic;

    /***************************************************************************************
    * calculate percentile based in age (as X axis) and registered VS value (weight, height, etc...) (as Y axis)
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Pedro Teixeira
    * @version    2.7
    * @since      28/09/2017
    ***************************************************************************************/
    FUNCTION calculate_percentile
    (
        i_lang               IN language.id_language%TYPE,
        i_id_graphic         IN graphic.id_graphic%TYPE,
        i_input_x_value      IN graphic_line_point.point_value_x%TYPE,
        i_input_y_value      IN graphic_line_point.point_value_y%TYPE,
        o_high_percentile    OUT graphic_line.line_value%TYPE,
        o_low_percentile     OUT graphic_line.line_value%TYPE,
        o_nearest_percentile OUT graphic_line.line_value%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'CALCULATE_PERCENTILE';
    
        l_low_value         graphic_line_point.point_value_y%TYPE;
        l_high_value        graphic_line_point.point_value_y%TYPE;
        l_reference_x_point graphic_line_point.point_value_x%TYPE;
    
        o_xmax NUMBER;
        o_xmin NUMBER;
    
        percentiles table_number;
        distances   table_number;
    BEGIN
      
        /*the following code uses linear algebra to calculate distances between points and straight lines*/
    
        -- see the min and max x value to consider depending on the input parameters (i_input_x_value, i_input_y_value)
        SELECT MAX(glp_1.point_value_x), MIN(glp_2.point_value_x)
          INTO o_xmax, o_xmin
          FROM graphic_line gl
          JOIN graphic_line_point glp_1
            ON glp_1.id_graphic_line = gl.id_graphic_line
          JOIN graphic_line_point glp_2
            ON glp_2.id_graphic_line = gl.id_graphic_line
         WHERE gl.id_graphic = i_id_graphic
           AND glp_1.point_value_x <= i_input_x_value
           AND glp_2.point_value_x >= i_input_x_value;
        
        -- if they are equal we can calculate immediately the distance between points
        IF o_xmax = o_xmin
        THEN
            SELECT percentiles, distance
              BULK COLLECT
              INTO percentiles, distances
              FROM (SELECT i_input_y_value - glp.point_value_y distance,
                           gl.line_value percentiles,
                           abs(i_input_y_value - glp.point_value_y) absolute_distance
                      FROM graphic_line_point glp
                      JOIN graphic_line gl
                        ON gl.id_graphic_line = glp.id_graphic_line
                     WHERE gl.id_graphic = i_id_graphic
                       AND glp.point_value_x = o_xmin
                     ORDER BY absolute_distance) t
             WHERE rownum <= 2;
             
        /* If they are not equal it will calculate the distances between the points and order this distances in an ascending order.
           Because we only need the above and below percentiles, this collection will only have 2 registers. It's relevant to point
           out that this collection ir ordered by distance in an ascending order.  
           This means that the first position of the collection will be the minor distance, equivelent to the nearest percentile.*/
        ELSE
            SELECT percentiles, distance
              BULK COLLECT
              INTO percentiles, distances
              FROM (SELECT (b + m * i_input_x_value - i_input_y_value) / sqrt(1 + power(m, 2)) distance,
                           line_value percentiles,
                           abs((b + m * i_input_x_value - i_input_y_value) / sqrt(1 + power(m, 2))) absolute_distance
                      FROM (SELECT p.*, ((y2 - y1) / (x2 - x1)) m, (y1 - ((y2 - y1) / (x2 - x1)) * x1) b
                              FROM (SELECT glp.point_value_y y1,
                                           lead(glp.point_value_y, 1) over(PARTITION BY glp.id_graphic_line ORDER BY glp.point_value_y ASC) AS y2,
                                           glp.point_value_x x1,
                                           lead(glp.point_value_x, 1) over(PARTITION BY glp.id_graphic_line ORDER BY glp.point_value_x ASC) AS x2,
                                           gl.line_value
                                      FROM graphic_line_point glp
                                      JOIN graphic_line gl
                                        ON gl.id_graphic_line = glp.id_graphic_line
                                     WHERE gl.id_graphic = i_id_graphic
                                       AND glp.point_value_x IN (o_xmin, o_xmax)) p
                             WHERE y2 IS NOT NULL) p
                     ORDER BY absolute_distance ASC) t
             WHERE rownum <= 2;
        END IF;
    
        IF distances.exists(1)
           AND distances IS NOT NULL
        THEN
            /*Now it's needed to verify if the distances in the collection has the same sign (positive or negative). If this 
              does happen it means that we are under a maximum or minimum percentile.*/
            IF sign(distances(1)) = sign(distances(2))
            THEN
               -- If the sign is positive it means we have a minimum percentile
                IF sign(distances(1)) = 1
                THEN
                    SELECT MIN(column_value)
                      INTO o_low_percentile
                      FROM TABLE(percentiles);
               -- If the sign is negative it means we have a maximum percentile                      
                ELSE
                    SELECT MAX(column_value)
                      INTO o_high_percentile
                      FROM TABLE(percentiles);
                END IF;
            END IF;
        END IF;
    
        -- In case we have a maximum or minimum percentile, they are the nearest percentile (one or another).
        IF o_low_percentile IS NOT NULL
           OR o_high_percentile IS NOT NULL
        THEN
            o_nearest_percentile := nvl(o_low_percentile, o_high_percentile);
        /*We need to return the above and the below percentiles.
          Because the collection is ordered by distance we know that the nearest percentile is the one in the first position of 
          the collection*/        
        ELSE
            SELECT MIN(column_value)
              INTO o_low_percentile
              FROM TABLE(percentiles);
        
            SELECT MAX(column_value)
              INTO o_high_percentile
              FROM TABLE(percentiles);
        
            o_nearest_percentile := percentiles(1);
        
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
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN FALSE;
    END calculate_percentile;

    /***************************************************************************************
    * gets percentile vital signs associated with pacient
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Pedro Teixeira
    * @version    2.7
    * @since      28/09/2017
    ***************************************************************************************/
    FUNCTION get_percentile_vs
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_flg_view      IN vs_soft_inst.flg_view%TYPE,
        o_percentile_vs OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_PERCENTILE_VS';
    
    BEGIN
        OPEN o_percentile_vs FOR
            SELECT vs_desc, VALUE, value_high, value_low
              FROM (SELECT pk_translation.get_translation(i_lang, vs.code_vital_sign) vs_desc,
                           vsr.value,
                           vsr.value_high,
                           vsr.value_low,
                           dense_rank() over(PARTITION BY vs.id_vital_sign ORDER BY vsr.dt_vital_sign_read_tstz DESC) rank
                      FROM vital_sign_read vsr
                      JOIN vital_sign vs
                        ON vsr.id_vital_sign = vs.id_vital_sign
                      JOIN vs_soft_inst vsi
                        ON vsi.id_vital_sign = vs.id_vital_sign
                       AND vsi.id_software = i_prof.software
                       AND vsi.id_institution = i_prof.institution
                       AND vsi.flg_view = i_flg_view
                     WHERE vsr.id_patient = i_patient
                       AND vsr.flg_state = pk_alert_constant.g_active
                       AND EXISTS (SELECT 1
                              FROM vital_sign_relation vsrel
                             WHERE vsrel.id_vital_sign_detail = vsr.id_vital_sign
                               AND vsrel.relation_domain = pk_alert_constant.g_vs_rel_percentile))
             WHERE rank = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_percentile_vs);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN FALSE;
    END get_percentile_vs;

BEGIN
    -- Log startup
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_percentile;
/
