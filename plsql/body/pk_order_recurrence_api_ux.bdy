/*-- Last Change Revision: $Rev: 2027403 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:07 +0100 (ter, 02 ago 2022) $*/


CREATE OR REPLACE PACKAGE BODY pk_order_recurrence_api_ux IS

    -- purpose: order recurrence UX api database package

    -- declared exceptions
    e_user_exception EXCEPTION;

    FUNCTION get_predefined_time_schedules
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_order_recurr_area     IN order_recurr_area.internal_name%TYPE,
        o_predef_time_schedules OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- call pk_order_recurrence_core.get_predefined_time_schedules function
        IF NOT pk_order_recurrence_core.get_predefined_time_schedules(i_lang                  => i_lang,
                                                                      i_prof                  => i_prof,
                                                                      i_order_recurr_area     => i_order_recurr_area,
                                                                      o_predef_time_schedules => o_predef_time_schedules,
                                                                      o_error                 => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.get_predefined_time_schedules function';
            RAISE e_user_exception;
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
                                              'GET_PREDEFINED_TIME_SCHEDULES',
                                              o_error);
            pk_types.open_my_cursor(o_predef_time_schedules);
            RETURN FALSE;
    END get_predefined_time_schedules;

    FUNCTION get_most_frequent_recurrences
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_order_recurr_area    IN order_recurr_area.internal_name%TYPE,
        o_order_recurr_options OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- call pk_order_recurrence_core.get_most_frequent_recurrences function
        IF NOT pk_order_recurrence_core.get_most_frequent_recurrences(i_lang                 => i_lang,
                                                                      i_prof                 => i_prof,
                                                                      i_order_recurr_area    => i_order_recurr_area,
                                                                      o_order_recurr_options => o_order_recurr_options,
                                                                      o_error                => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.get_most_frequent_recurrences function';
            RAISE e_user_exception;
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
                                              'GET_MOST_FREQUENT_RECURRENCES',
                                              o_error);
            pk_types.open_my_cursor(o_order_recurr_options);
            RETURN FALSE;
    END get_most_frequent_recurrences;

    FUNCTION get_order_recurr_plan_end
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_domain            IN VARCHAR2,
        i_flg_context       IN VARCHAR2,
        o_domains           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        -- call pk_order_recurrence_core.get_order_recurr_plan_end function
        IF NOT pk_order_recurrence_core.get_order_recurr_plan_end(i_lang        => i_lang,
                                                                  i_prof        => i_prof,
                                                                  i_domain      => i_domain,
                                                                  i_flg_context => i_flg_context,
                                                                  o_domains     => o_domains,
                                                                  o_error       => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.get_order_recurr_plan_end function';
            RAISE e_user_exception;
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
                                              'GET_ORDER_RECURR_PLAN_END',
                                              o_error);
            pk_types.open_my_cursor(o_domains);
            RETURN FALSE;
    END get_order_recurr_plan_end;

    FUNCTION get_order_recurr_plan_end
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_domain      IN VARCHAR2,
        i_flg_context IN VARCHAR2,
        o_domains     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        -- call pk_order_recurrence_core.get_order_recurr_plan_end function
        IF NOT pk_order_recurrence_core.get_order_recurr_plan_end(i_lang        => i_lang,
                                                                  i_prof        => i_prof,
                                                                  i_domain      => i_domain,
                                                                  i_flg_context => i_flg_context,
                                                                  o_domains     => o_domains,
                                                                  o_error       => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.get_order_recurr_plan_end function';
            RAISE e_user_exception;
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
                                              'GET_ORDER_RECURR_PLAN_END',
                                              o_error);
            pk_types.open_my_cursor(o_domains);
            RETURN FALSE;
    END get_order_recurr_plan_end;

    FUNCTION create_order_recurr_plan
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_order_recurr_area   IN order_recurr_area.internal_name%TYPE,
        o_order_recurr_desc   OUT VARCHAR2,
        o_order_recurr_option OUT order_recurr_plan.id_order_recurr_option%TYPE,
        o_start_date          OUT VARCHAR2,
        o_occurrences         OUT order_recurr_plan.occurrences%TYPE,
        o_duration            OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration  OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_duration_desc       OUT VARCHAR2,
        o_end_date            OUT VARCHAR2,
        o_flg_end_by_editable OUT VARCHAR2,
        o_order_recurr_plan   OUT order_recurr_plan.id_order_recurr_plan%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        -- call pk_order_recurrence_core.create_order_recurr_plan function
        IF NOT pk_order_recurrence_core.create_order_recurr_plan(i_lang                => i_lang,
                                                                 i_prof                => i_prof,
                                                                 i_order_recurr_area   => i_order_recurr_area,
                                                                 o_order_recurr_desc   => o_order_recurr_desc,
                                                                 o_order_recurr_option => o_order_recurr_option,
                                                                 o_start_date          => l_start_date,
                                                                 o_occurrences         => o_occurrences,
                                                                 o_duration            => o_duration,
                                                                 o_unit_meas_duration  => o_unit_meas_duration,
                                                                 o_end_date            => l_end_date,
                                                                 o_flg_end_by_editable => o_flg_end_by_editable,
                                                                 o_order_recurr_plan   => o_order_recurr_plan,
                                                                 o_error               => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.create_order_recurr_plan function';
            RAISE e_user_exception;
        END IF;
    
        -- convert start date and end date to the format supported by the Flash layer
        o_start_date := pk_date_utils.date_send_tsz(i_lang, l_start_date, i_prof);
        o_end_date   := pk_date_utils.date_send_tsz(i_lang, l_end_date, i_prof);
    
        -- process duration description
        IF o_duration IS NOT NULL
        THEN
            o_duration_desc := o_duration || ' ' ||
                               pk_unit_measure.get_unit_measure_description(i_lang, i_prof, o_unit_meas_duration);
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_ORDER_RECURR_PLAN',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_order_recurr_plan;

    FUNCTION create_order_recurr_plan_predf
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_order_recurr_area   IN order_recurr_area.internal_name%TYPE,
        i_num_task_reqs       IN NUMBER,
        o_order_recurr_desc   OUT VARCHAR2,
        o_order_recurr_option OUT order_recurr_plan.id_order_recurr_option%TYPE,
        o_start_date          OUT VARCHAR2,
        o_occurrences         OUT order_recurr_plan.occurrences%TYPE,
        o_duration            OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration  OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_duration_desc       OUT VARCHAR2,
        o_end_date            OUT VARCHAR2,
        o_flg_end_by_editable OUT VARCHAR2,
        o_order_recurr_plans  OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        IF i_num_task_reqs IS NULL
           OR i_num_task_reqs = 0
        THEN
            g_error := 'number of tasks requests cannot be null or 0';
            RAISE e_user_exception;
        END IF;
    
        g_error              := 'Init create_order_recurr_plan_predf';
        o_order_recurr_plans := table_number();
        o_order_recurr_plans.extend(i_num_task_reqs);
    
        g_error := 'FOR i IN 1 .. ' || i_num_task_reqs;
        FOR i IN 1 .. i_num_task_reqs
        LOOP
            -- call pk_order_recurrence_core.create_order_recurr_plan function
            IF NOT pk_order_recurrence_core.create_order_recurr_plan(i_lang                => i_lang,
                                                                     i_prof                => i_prof,
                                                                     i_order_recurr_area   => i_order_recurr_area,
                                                                     i_flg_status          => pk_order_recurrence_core.g_plan_status_predefined,
                                                                     o_order_recurr_desc   => o_order_recurr_desc,
                                                                     o_order_recurr_option => o_order_recurr_option,
                                                                     o_start_date          => l_start_date,
                                                                     o_occurrences         => o_occurrences,
                                                                     o_duration            => o_duration,
                                                                     o_unit_meas_duration  => o_unit_meas_duration,
                                                                     o_end_date            => l_end_date,
                                                                     o_flg_end_by_editable => o_flg_end_by_editable,
                                                                     o_order_recurr_plan   => o_order_recurr_plans(i),
                                                                     o_error               => o_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.create_order_recurr_plan function / i_order_recurr_area=' ||
                           i_order_recurr_area;
                RAISE e_user_exception;
            END IF;
        
        END LOOP;
    
        -- convert start date and end date to the format supported by the Flash layer
        o_start_date := pk_date_utils.date_send_tsz(i_lang, l_start_date, i_prof);
        o_end_date   := pk_date_utils.date_send_tsz(i_lang, l_end_date, i_prof);
    
        -- process duration description
        IF o_duration IS NOT NULL
        THEN
            o_duration_desc := o_duration || ' ' ||
                               pk_unit_measure.get_unit_measure_description(i_lang, i_prof, o_unit_meas_duration);
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_ORDER_RECURR_PLAN_PREDF',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_order_recurr_plan_predf;

    FUNCTION copy_order_recurr_plan
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_order_recurr_plan_from IN order_recurr_plan.id_order_recurr_plan%TYPE,
        o_order_recurr_desc      OUT VARCHAR2,
        o_order_recurr_option    OUT order_recurr_plan.id_order_recurr_option%TYPE,
        o_start_date             OUT VARCHAR2,
        o_occurrences            OUT order_recurr_plan.occurrences%TYPE,
        o_duration               OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration     OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_duration_desc          OUT VARCHAR2,
        o_end_date               OUT VARCHAR2,
        o_flg_end_by_editable    OUT VARCHAR2,
        o_order_recurr_plan      OUT order_recurr_plan.id_order_recurr_plan%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        -- call pk_order_recurrence_core.copy_order_recurr_plan function
        IF NOT pk_order_recurrence_core.copy_order_recurr_plan(i_lang                   => i_lang,
                                                               i_prof                   => i_prof,
                                                               i_order_recurr_plan_from => i_order_recurr_plan_from,
                                                               o_order_recurr_desc      => o_order_recurr_desc,
                                                               o_order_recurr_option    => o_order_recurr_option,
                                                               o_start_date             => l_start_date,
                                                               o_occurrences            => o_occurrences,
                                                               o_duration               => o_duration,
                                                               o_unit_meas_duration     => o_unit_meas_duration,
                                                               o_end_date               => l_end_date,
                                                               o_flg_end_by_editable    => o_flg_end_by_editable,
                                                               o_order_recurr_plan      => o_order_recurr_plan,
                                                               o_error                  => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.copy_order_recurr_plan function';
            RAISE e_user_exception;
        END IF;
    
        -- convert start date and end date to the format supported by the Flash layer
        o_start_date := pk_date_utils.date_send_tsz(i_lang, l_start_date, i_prof);
        o_end_date   := pk_date_utils.date_send_tsz(i_lang, l_end_date, i_prof);
    
        -- process duration description
        IF o_duration IS NOT NULL
        THEN
            o_duration_desc := o_duration || ' ' ||
                               pk_unit_measure.get_unit_measure_description(i_lang, i_prof, o_unit_meas_duration);
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'COPY_ORDER_RECURR_PLAN',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END copy_order_recurr_plan;

    FUNCTION edit_order_recurr_plan
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_order_recurr_area      IN order_recurr_area.internal_name%TYPE,
        i_order_recurr_option    IN order_recurr_plan.id_order_recurr_option%TYPE DEFAULT NULL,
        i_start_date             IN VARCHAR2,
        i_occurrences            IN order_recurr_plan.occurrences%TYPE,
        i_duration               IN order_recurr_plan.duration%TYPE,
        i_unit_meas_duration     IN order_recurr_plan.id_unit_meas_duration%TYPE,
        i_end_date               IN VARCHAR2,
        i_order_recurr_plan_from IN order_recurr_plan.id_order_recurr_plan%TYPE,
        o_order_recurr_desc      OUT VARCHAR2,
        o_order_recurr_option    OUT order_recurr_plan.id_order_recurr_option%TYPE,
        o_start_date             OUT VARCHAR2,
        o_occurrences            OUT order_recurr_plan.occurrences%TYPE,
        o_duration               OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration     OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_duration_desc          OUT VARCHAR2,
        o_end_date               OUT VARCHAR2,
        o_flg_end_by_editable    OUT VARCHAR2,
        o_order_recurr_plan      OUT order_recurr_plan.id_order_recurr_plan%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        -- call pk_order_recurrence_core.copy_order_recurr_plan function
        IF NOT pk_order_recurrence_core.edit_order_recurr_plan(i_lang                   => i_lang,
                                                               i_prof                   => i_prof,
                                                               i_order_recurr_area      => i_order_recurr_area,
                                                               i_order_recurr_option    => i_order_recurr_option,
                                                               i_start_date             => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                         i_prof,
                                                                                                                         i_start_date,
                                                                                                                         NULL),
                                                               i_occurrences            => i_occurrences,
                                                               i_duration               => i_duration,
                                                               i_unit_meas_duration     => i_unit_meas_duration,
                                                               i_end_date               => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                         i_prof,
                                                                                                                         i_end_date,
                                                                                                                         NULL),
                                                               i_order_recurr_plan_from => i_order_recurr_plan_from,
                                                               o_order_recurr_desc      => o_order_recurr_desc,
                                                               o_order_recurr_option    => o_order_recurr_option,
                                                               o_start_date             => l_start_date,
                                                               o_occurrences            => o_occurrences,
                                                               o_duration               => o_duration,
                                                               o_unit_meas_duration     => o_unit_meas_duration,
                                                               o_end_date               => l_end_date,
                                                               o_flg_end_by_editable    => o_flg_end_by_editable,
                                                               o_order_recurr_plan      => o_order_recurr_plan,
                                                               o_error                  => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.edit_order_recurr_plan function';
            RAISE e_user_exception;
        END IF;
    
        -- convert start date and end date to the format supported by the Flash layer
        o_start_date := pk_date_utils.date_send_tsz(i_lang, l_start_date, i_prof);
        o_end_date   := pk_date_utils.date_send_tsz(i_lang, l_end_date, i_prof);
    
        -- process duration description
        IF o_duration IS NOT NULL
        THEN
            o_duration_desc := o_duration || ' ' ||
                               pk_unit_measure.get_unit_measure_description(i_lang, i_prof, o_unit_meas_duration);
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'EDIT_ORDER_RECURR_PLAN',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END edit_order_recurr_plan;

    FUNCTION set_order_recurr_option
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_order_recurr_plan   IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE,
        o_order_recurr_desc   OUT VARCHAR2,
        o_order_recurr_option OUT order_recurr_plan.id_order_recurr_option%TYPE,
        o_start_date          OUT VARCHAR2,
        o_occurrences         OUT order_recurr_plan.occurrences%TYPE,
        o_duration            OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration  OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_duration_desc       OUT VARCHAR2,
        o_end_date            OUT VARCHAR2,
        o_flg_end_by_editable OUT VARCHAR2,
        o_order_recurr_plan   OUT order_recurr_plan.id_order_recurr_plan%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_order_recurr_plans table_number;
    BEGIN
    
        -- call set_order_recurr_option function
        IF NOT set_order_recurr_option(i_lang                => i_lang,
                                       i_prof                => i_prof,
                                       i_order_recurr_plans  => table_number(i_order_recurr_plan),
                                       i_order_recurr_option => i_order_recurr_option,
                                       o_order_recurr_desc   => o_order_recurr_desc,
                                       o_order_recurr_option => o_order_recurr_option,
                                       o_start_date          => o_start_date,
                                       o_occurrences         => o_occurrences,
                                       o_duration            => o_duration,
                                       o_unit_meas_duration  => o_unit_meas_duration,
                                       o_duration_desc       => o_duration_desc,
                                       o_end_date            => o_end_date,
                                       o_flg_end_by_editable => o_flg_end_by_editable,
                                       o_order_recurr_plans  => l_order_recurr_plans,
                                       o_error               => o_error)
        THEN
            g_error := 'error found while calling set_order_recurr_option function';
            RAISE e_user_exception;
        END IF;
    
        -- assign output variables
        o_order_recurr_plan := l_order_recurr_plans(1);
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ORDER_RECURR_OPTION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_order_recurr_option;

    FUNCTION set_order_recurr_option
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_order_recurr_plans  IN table_number,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE,
        o_order_recurr_desc   OUT VARCHAR2,
        o_order_recurr_option OUT order_recurr_plan.id_order_recurr_option%TYPE,
        o_start_date          OUT VARCHAR2,
        o_occurrences         OUT order_recurr_plan.occurrences%TYPE,
        o_duration            OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration  OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_duration_desc       OUT VARCHAR2,
        o_end_date            OUT VARCHAR2,
        o_flg_end_by_editable OUT VARCHAR2,
        o_order_recurr_plans  OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        IF i_order_recurr_plans IS NULL
           OR i_order_recurr_plans.count = 0
        THEN
            g_error := 'order recurrence plan ids cannot be empty';
            RAISE e_user_exception;
        ELSIF i_order_recurr_plans(1) IS NULL
        THEN
            RETURN TRUE;
        
        END IF;
    
        g_error              := 'Init set_order_recurr_option / i_order_recurr_option=' || i_order_recurr_option;
        o_order_recurr_plans := table_number();
        o_order_recurr_plans.extend(i_order_recurr_plans.count);
    
        g_error := 'FOR i IN 1 .. ' || i_order_recurr_plans.count;
        FOR i IN 1 .. i_order_recurr_plans.count
        LOOP
            -- call pk_order_recurrence_core.set_order_recurr_option function
            IF NOT pk_order_recurrence_core.set_order_recurr_option(i_lang                => i_lang,
                                                                    i_prof                => i_prof,
                                                                    i_order_recurr_plan   => i_order_recurr_plans(i),
                                                                    i_order_recurr_option => i_order_recurr_option,
                                                                    o_order_recurr_desc   => o_order_recurr_desc,
                                                                    o_start_date          => l_start_date,
                                                                    o_occurrences         => o_occurrences,
                                                                    o_duration            => o_duration,
                                                                    o_unit_meas_duration  => o_unit_meas_duration,
                                                                    o_end_date            => l_end_date,
                                                                    o_flg_end_by_editable => o_flg_end_by_editable,
                                                                    o_error               => o_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.set_order_recurr_option function';
                RAISE e_user_exception;
            END IF;
        
            -- assign output variable
            o_order_recurr_plans(i) := i_order_recurr_plans(i);
        
        END LOOP;
    
        -- convert start date and end date to the format supported by the Flash layer
        o_start_date := pk_date_utils.date_send_tsz(i_lang, l_start_date, i_prof);
        o_end_date   := pk_date_utils.date_send_tsz(i_lang, l_end_date, i_prof);
    
        -- process duration description
        IF o_duration IS NOT NULL
        THEN
            o_duration_desc := o_duration || ' ' ||
                               pk_unit_measure.get_unit_measure_description(i_lang, i_prof, o_unit_meas_duration);
        END IF;
    
        -- assign remain output variables
        o_order_recurr_option := i_order_recurr_option;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ORDER_RECURR_OPTION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_order_recurr_option;

    FUNCTION set_order_recurr_option
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_order_recurr_plan   IN table_number,
        i_order_recurr_option IN table_number,
        o_order_recurr_plan   OUT table_number,
        o_order_recurr_desc   OUT table_varchar,
        o_order_recurr_option OUT table_number,
        o_start_date          OUT table_varchar,
        o_occurrences         OUT table_number,
        o_duration            OUT table_number,
        o_unit_meas_duration  OUT table_number,
        o_duration_desc       OUT table_varchar,
        o_end_date            OUT table_varchar,
        o_flg_end_by_editable OUT table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_order_recurr_desc   VARCHAR2(1000 CHAR);
        l_start_date          order_recurr_plan.start_date%TYPE;
        l_occurrences         order_recurr_plan.occurrences%TYPE;
        l_duration            order_recurr_plan.duration%TYPE;
        l_unit_meas_duration  order_recurr_plan.id_unit_meas_duration%TYPE;
        l_end_date            order_recurr_plan.end_date%TYPE;
        l_flg_end_by_editable VARCHAR2(1 CHAR);
    
    BEGIN
    
        IF i_order_recurr_plan IS NULL
           OR i_order_recurr_plan.count = 0
        THEN
            g_error := 'order recurrence plan ids cannot be empty';
            RAISE e_user_exception;
        ELSIF i_order_recurr_plan(1) IS NULL
        THEN
            RETURN TRUE;
        END IF;
    
        o_order_recurr_plan := table_number();
        o_order_recurr_plan.extend(i_order_recurr_plan.count);
    
        o_order_recurr_plan   := table_number();
        o_order_recurr_desc   := table_varchar();
        o_order_recurr_option := table_number();
        o_start_date          := table_varchar();
        o_occurrences         := table_number();
        o_duration            := table_number();
        o_unit_meas_duration  := table_number();
        o_duration_desc       := table_varchar();
        o_end_date            := table_varchar();
        o_flg_end_by_editable := table_varchar();
    
        g_error := 'FOR i IN 1 .. ' || i_order_recurr_plan.count;
        FOR i IN 1 .. i_order_recurr_plan.count
        LOOP
            g_error := 'Init set_order_recurr_option / i_order_recurr_option=' || i_order_recurr_option(i);
        
            -- call pk_order_recurrence_core.set_order_recurr_option function
            IF NOT pk_order_recurrence_core.set_order_recurr_option(i_lang                => i_lang,
                                                                    i_prof                => i_prof,
                                                                    i_order_recurr_plan   => i_order_recurr_plan(i),
                                                                    i_order_recurr_option => i_order_recurr_option(i),
                                                                    o_order_recurr_desc   => l_order_recurr_desc,
                                                                    o_start_date          => l_start_date,
                                                                    o_occurrences         => l_occurrences,
                                                                    o_duration            => l_duration,
                                                                    o_unit_meas_duration  => l_unit_meas_duration,
                                                                    o_end_date            => l_end_date,
                                                                    o_flg_end_by_editable => l_flg_end_by_editable,
                                                                    o_error               => o_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.set_order_recurr_option function';
                RAISE e_user_exception;
            END IF;
        
            o_order_recurr_desc.extend;
            o_order_recurr_option.extend;
            o_start_date.extend;
            o_occurrences.extend;
            o_duration.extend;
            o_unit_meas_duration.extend;
            o_duration_desc.extend;
            o_end_date.extend;
            o_flg_end_by_editable.extend;
            o_order_recurr_plan.extend;
        
            -- assign output variable
            o_order_recurr_plan(i) := i_order_recurr_plan(i);
        
            o_order_recurr_desc(i) := l_order_recurr_desc;
            o_order_recurr_option(i) := i_order_recurr_option(i);
            o_start_date(i) := pk_date_utils.date_send_tsz(i_lang, l_start_date, i_prof);
            o_occurrences(i) := l_occurrences;
            o_duration(i) := l_duration;
            o_unit_meas_duration(i) := l_unit_meas_duration;
            o_end_date(i) := pk_date_utils.date_send_tsz(i_lang, l_end_date, i_prof);
            o_flg_end_by_editable(i) := l_flg_end_by_editable;
        
            -- process duration description
            IF l_duration IS NOT NULL
            THEN
                o_duration_desc(i) := l_duration || ' ' ||
                                      pk_unit_measure.get_unit_measure_description(i_lang, i_prof, l_unit_meas_duration);
            END IF;
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ORDER_RECURR_OPTION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_order_recurr_option;

    FUNCTION set_order_recurr_instructions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_order_recurr_plan   IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_start_date          IN VARCHAR2,
        i_occurrences         IN order_recurr_plan.occurrences%TYPE,
        i_duration            IN order_recurr_plan.duration%TYPE,
        i_unit_meas_duration  IN order_recurr_plan.id_unit_meas_duration%TYPE,
        i_end_date            IN VARCHAR2,
        o_order_recurr_desc   OUT VARCHAR2,
        o_order_recurr_option OUT order_recurr_plan.id_order_recurr_option%TYPE,
        o_start_date          OUT VARCHAR2,
        o_occurrences         OUT order_recurr_plan.occurrences%TYPE,
        o_duration            OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration  OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_duration_desc       OUT VARCHAR2,
        o_end_date            OUT VARCHAR2,
        o_flg_end_by_editable OUT VARCHAR2,
        o_order_recurr_plan   OUT order_recurr_plan.id_order_recurr_plan%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_order_recurr_plans table_number;
    BEGIN
        -- call set_order_recurr_instructions function
        IF NOT set_order_recurr_instructions(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_order_recurr_plans  => table_number(i_order_recurr_plan),
                                             i_start_date          => i_start_date,
                                             i_occurrences         => i_occurrences,
                                             i_duration            => i_duration,
                                             i_unit_meas_duration  => i_unit_meas_duration,
                                             i_end_date            => i_end_date,
                                             o_order_recurr_desc   => o_order_recurr_desc,
                                             o_order_recurr_option => o_order_recurr_option,
                                             o_start_date          => o_start_date,
                                             o_occurrences         => o_occurrences,
                                             o_duration            => o_duration,
                                             o_unit_meas_duration  => o_unit_meas_duration,
                                             o_duration_desc       => o_duration_desc,
                                             o_end_date            => o_end_date,
                                             o_flg_end_by_editable => o_flg_end_by_editable,
                                             o_order_recurr_plans  => l_order_recurr_plans,
                                             o_error               => o_error)
        THEN
            g_error := 'error found while calling set_order_recurr_instructions function';
            RAISE e_user_exception;
        END IF;
    
        -- assign output variable
        o_order_recurr_plan := l_order_recurr_plans(1);
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ORDER_RECURR_INSTRUCTIONS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_order_recurr_instructions;

    FUNCTION set_order_recurr_instructions
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_order_recurr_plan    IN table_number,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_val              IN table_table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_start_date         table_varchar := table_varchar();
        l_tbl_occurrences        table_number := table_number();
        l_tbl_duration           table_number := table_number();
        l_tbl_unit_meas_duration table_number := table_number();
        l_tbl_end_date           table_varchar := table_varchar();
    
        l_order_recurr_desc   VARCHAR2(1000 CHAR);
        l_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
        l_start_date          order_recurr_plan.start_date%TYPE;
        l_occurrences         order_recurr_plan.occurrences%TYPE;
        l_duration            order_recurr_plan.duration%TYPE;
        l_unit_meas_duration  order_recurr_plan.id_unit_meas_duration%TYPE;
        l_end_date            order_recurr_plan.end_date%TYPE;
        l_flg_end_by_editable VARCHAR2(1 CHAR);
    
    BEGIN
    
        IF i_order_recurr_plan IS NULL
           OR i_order_recurr_plan.count = 0
        THEN
            g_error := 'order recurrence plan ids cannot be empty';
            RAISE e_user_exception;
        END IF;
    
        FOR i IN i_order_recurr_plan.first .. i_order_recurr_plan.last
        LOOP
            FOR j IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
            LOOP
                IF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_start_date
                THEN
                    l_tbl_start_date.extend();
                    l_tbl_start_date(l_tbl_start_date.count) := i_tbl_real_val(j) (i);
                END IF;
            END LOOP;
        
            l_tbl_occurrences.extend();
            l_tbl_duration.extend();
            l_tbl_unit_meas_duration.extend();
            l_tbl_end_date.extend();
        
        END LOOP;
    
        g_error := 'FOR i IN 1 .. ' || i_order_recurr_plan.count;
        FOR i IN 1 .. i_order_recurr_plan.count
        LOOP
            g_error := 'Init set_order_recurr_instructions / i_start_date=' || l_tbl_start_date(i) || ' i_occurrences=' ||
                       l_tbl_occurrences(i) || ' i_duration=' || l_tbl_duration(i) || ' i_unit_meas_duration=' ||
                       l_tbl_unit_meas_duration(i) || ' i_end_date=' || l_tbl_end_date(i);
        
            -- call pk_order_recurrence_core.set_order_recurr_instructions function
            IF NOT pk_order_recurrence_core.set_order_recurr_instructions(i_lang                => i_lang,
                                                                          i_prof                => i_prof,
                                                                          i_order_recurr_plan   => i_order_recurr_plan(i),
                                                                          i_start_date          => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 l_tbl_start_date(i),
                                                                                                                                 NULL),
                                                                          i_occurrences         => l_tbl_occurrences(i),
                                                                          i_duration            => l_tbl_duration(i),
                                                                          i_unit_meas_duration  => l_tbl_unit_meas_duration(i),
                                                                          i_end_date            => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 l_tbl_end_date(i),
                                                                                                                                 NULL),
                                                                          o_order_recurr_desc   => l_order_recurr_desc,
                                                                          o_start_date          => l_start_date,
                                                                          o_order_recurr_option => l_order_recurr_option,
                                                                          o_occurrences         => l_occurrences,
                                                                          o_duration            => l_duration,
                                                                          o_unit_meas_duration  => l_unit_meas_duration,
                                                                          o_end_date            => l_end_date,
                                                                          o_flg_end_by_editable => l_flg_end_by_editable,
                                                                          o_error               => o_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.set_order_recurr_instructions function';
                RAISE e_user_exception;
            END IF;
        END LOOP;
    
        -- process duration description
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ORDER_RECURR_INSTRUCTIONS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_order_recurr_instructions;

    FUNCTION set_order_recurr_instructions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_order_recurr_plans  IN table_number,
        i_start_date          IN VARCHAR2,
        i_occurrences         IN order_recurr_plan.occurrences%TYPE,
        i_duration            IN order_recurr_plan.duration%TYPE,
        i_unit_meas_duration  IN order_recurr_plan.id_unit_meas_duration%TYPE,
        i_end_date            IN VARCHAR2,
        o_order_recurr_desc   OUT VARCHAR2,
        o_order_recurr_option OUT order_recurr_plan.id_order_recurr_option%TYPE,
        o_start_date          OUT VARCHAR2,
        o_occurrences         OUT order_recurr_plan.occurrences%TYPE,
        o_duration            OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration  OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_duration_desc       OUT VARCHAR2,
        o_end_date            OUT VARCHAR2,
        o_flg_end_by_editable OUT VARCHAR2,
        o_order_recurr_plans  OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        IF i_order_recurr_plans IS NULL
           OR i_order_recurr_plans.count = 0
        THEN
            g_error := 'order recurrence plan ids cannot be empty';
            RAISE e_user_exception;
        END IF;
    
        g_error              := 'Init set_order_recurr_instructions / i_start_date=' || i_start_date ||
                                ' i_occurrences=' || i_occurrences || ' i_duration=' || i_duration ||
                                ' i_unit_meas_duration=' || i_unit_meas_duration || ' i_end_date=' || i_end_date;
        o_order_recurr_plans := table_number();
        o_order_recurr_plans.extend(i_order_recurr_plans.count);
    
        g_error := 'FOR i IN 1 .. ' || i_order_recurr_plans.count;
        FOR i IN 1 .. i_order_recurr_plans.count
        LOOP
            -- call pk_order_recurrence_core.set_order_recurr_instructions function
            IF NOT pk_order_recurrence_core.set_order_recurr_instructions(i_lang                => i_lang,
                                                                          i_prof                => i_prof,
                                                                          i_order_recurr_plan   => i_order_recurr_plans(i),
                                                                          i_start_date          => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 i_start_date,
                                                                                                                                 NULL),
                                                                          i_occurrences         => i_occurrences,
                                                                          i_duration            => i_duration,
                                                                          i_unit_meas_duration  => i_unit_meas_duration,
                                                                          i_end_date            => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 i_end_date,
                                                                                                                                 NULL),
                                                                          o_order_recurr_desc   => o_order_recurr_desc,
                                                                          o_start_date          => l_start_date,
                                                                          o_order_recurr_option => o_order_recurr_option,
                                                                          o_occurrences         => o_occurrences,
                                                                          o_duration            => o_duration,
                                                                          o_unit_meas_duration  => o_unit_meas_duration,
                                                                          o_end_date            => l_end_date,
                                                                          o_flg_end_by_editable => o_flg_end_by_editable,
                                                                          o_error               => o_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.set_order_recurr_instructions function';
                RAISE e_user_exception;
            END IF;
        
            -- assign output variable
            o_order_recurr_plans(i) := i_order_recurr_plans(i);
        
        END LOOP;
    
        -- convert start date and end date to the format supported by the Flash layer
        o_start_date := pk_date_utils.date_send_tsz(i_lang, l_start_date, i_prof);
        o_end_date   := pk_date_utils.date_send_tsz(i_lang, l_end_date, i_prof);
    
        -- process duration description
        IF o_duration IS NOT NULL
        THEN
            o_duration_desc := o_duration || ' ' ||
                               pk_unit_measure.get_unit_measure_description(i_lang, i_prof, o_unit_meas_duration);
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ORDER_RECURR_INSTRUCTIONS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_order_recurr_instructions;

    FUNCTION set_order_recurr_instructions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_order_recurr_plan   IN table_number,
        i_start_date          IN table_varchar,
        i_occurrences         IN table_number,
        i_duration            IN table_number,
        i_unit_meas_duration  IN table_number,
        i_end_date            IN table_varchar,
        o_order_recurr_plan   OUT table_number,
        o_order_recurr_desc   OUT table_varchar,
        o_order_recurr_option OUT table_number,
        o_start_date          OUT table_varchar,
        o_occurrences         OUT table_number,
        o_duration            OUT table_number,
        o_unit_meas_duration  OUT table_number,
        o_duration_desc       OUT table_varchar,
        o_end_date            OUT table_varchar,
        o_flg_end_by_editable OUT table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_order_recurr_desc   VARCHAR2(1000 CHAR);
        l_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
        l_start_date          order_recurr_plan.start_date%TYPE;
        l_occurrences         order_recurr_plan.occurrences%TYPE;
        l_duration            order_recurr_plan.duration%TYPE;
        l_unit_meas_duration  order_recurr_plan.id_unit_meas_duration%TYPE;
        l_end_date            order_recurr_plan.end_date%TYPE;
        l_flg_end_by_editable VARCHAR2(1 CHAR);
    
    BEGIN
    
        IF i_order_recurr_plan IS NULL
           OR i_order_recurr_plan.count = 0
        THEN
            g_error := 'order recurrence plan ids cannot be empty';
            RAISE e_user_exception;
        END IF;
    
        o_order_recurr_plan   := table_number();
        o_order_recurr_desc   := table_varchar();
        o_order_recurr_option := table_number();
        o_start_date          := table_varchar();
        o_occurrences         := table_number();
        o_duration            := table_number();
        o_unit_meas_duration  := table_number();
        o_duration_desc       := table_varchar();
        o_end_date            := table_varchar();
        o_flg_end_by_editable := table_varchar();
    
        g_error := 'FOR i IN 1 .. ' || i_order_recurr_plan.count;
        FOR i IN 1 .. i_order_recurr_plan.count
        LOOP
            g_error := 'Init set_order_recurr_instructions / i_start_date=' || i_start_date(i) || ' i_occurrences=' ||
                       i_occurrences(i) || ' i_duration=' || i_duration(i) || ' i_unit_meas_duration=' ||
                       i_unit_meas_duration(i) || ' i_end_date=' || i_end_date(i);
        
            -- call pk_order_recurrence_core.set_order_recurr_instructions function
            IF NOT pk_order_recurrence_core.set_order_recurr_instructions(i_lang                => i_lang,
                                                                          i_prof                => i_prof,
                                                                          i_order_recurr_plan   => i_order_recurr_plan(i),
                                                                          i_start_date          => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 i_start_date(i),
                                                                                                                                 NULL),
                                                                          i_occurrences         => i_occurrences(i),
                                                                          i_duration            => i_duration(i),
                                                                          i_unit_meas_duration  => i_unit_meas_duration(i),
                                                                          i_end_date            => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 i_end_date(i),
                                                                                                                                 NULL),
                                                                          o_order_recurr_desc   => l_order_recurr_desc,
                                                                          o_start_date          => l_start_date,
                                                                          o_order_recurr_option => l_order_recurr_option,
                                                                          o_occurrences         => l_occurrences,
                                                                          o_duration            => l_duration,
                                                                          o_unit_meas_duration  => l_unit_meas_duration,
                                                                          o_end_date            => l_end_date,
                                                                          o_flg_end_by_editable => l_flg_end_by_editable,
                                                                          o_error               => o_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.set_order_recurr_instructions function';
                RAISE e_user_exception;
            END IF;
        
            o_order_recurr_desc.extend;
            o_order_recurr_option.extend;
            o_start_date.extend;
            o_occurrences.extend;
            o_duration.extend;
            o_unit_meas_duration.extend;
            o_duration_desc.extend;
            o_end_date.extend;
            o_flg_end_by_editable.extend;
            o_order_recurr_plan.extend;
        
            -- assign output variable
            o_order_recurr_plan(i) := i_order_recurr_plan(i);
        
            o_order_recurr_desc(i) := l_order_recurr_desc;
            o_order_recurr_option(i) := l_order_recurr_option;
        
            o_start_date(i) := pk_date_utils.date_send_tsz(i_lang, l_start_date, i_prof);
            o_end_date(i) := pk_date_utils.date_send_tsz(i_lang, l_end_date, i_prof);
        
            o_flg_end_by_editable(i) := l_flg_end_by_editable;
            o_occurrences(i) := l_occurrences;
            o_duration(i) := l_duration;
            o_unit_meas_duration(i) := l_unit_meas_duration;
        
            IF l_duration IS NOT NULL
            THEN
                o_duration_desc(i) := l_duration || ' ' ||
                                      pk_unit_measure.get_unit_measure_description(i_lang, i_prof, l_unit_meas_duration);
            END IF;
        END LOOP;
    
        -- convert start date and end date to the format supported by the Flash layer
    
        -- process duration description
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ORDER_RECURR_INSTRUCTIONS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_order_recurr_instructions;

    FUNCTION set_other_order_recurr_option
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_order_recurr_plan          IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_regular_interval           IN order_recurr_plan.regular_interval%TYPE,
        i_unit_meas_regular_interval IN order_recurr_plan.id_unit_meas_regular_interval%TYPE,
        i_daily_executions           IN order_recurr_plan.daily_executions%TYPE,
        i_predef_time_sched          IN table_number,
        i_exec_time_parent_option    IN table_number,
        i_exec_time_option           IN table_number,
        i_exec_time                  IN table_varchar,
        i_exec_time_offset           IN table_number,
        i_unit_meas_exec_time_offset IN table_number,
        i_flg_recurr_pattern         IN order_recurr_plan.flg_recurr_pattern%TYPE,
        i_repeat_every               IN order_recurr_plan.repeat_every%TYPE,
        i_flg_repeat_by              IN order_recurr_plan.flg_repeat_by%TYPE,
        i_start_date                 IN VARCHAR2,
        i_flg_end_by                 IN order_recurr_plan.flg_end_by%TYPE,
        i_occurrences                IN order_recurr_plan.occurrences%TYPE,
        i_duration                   IN order_recurr_plan.duration%TYPE,
        i_unit_meas_duration         IN order_recurr_plan.id_unit_meas_duration%TYPE,
        i_end_date                   IN VARCHAR2,
        i_flg_week_day               IN table_number,
        i_flg_week                   IN table_number,
        i_month_day                  IN table_number,
        i_month                      IN table_number,
        i_flg_context                IN VARCHAR2,
        o_order_recurr_desc          OUT VARCHAR2,
        o_order_recurr_option        OUT order_recurr_plan.id_order_recurr_option%TYPE,
        o_start_date                 OUT VARCHAR2,
        o_occurrences                OUT order_recurr_plan.occurrences%TYPE,
        o_duration                   OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration         OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_duration_desc              OUT VARCHAR2,
        o_end_date                   OUT VARCHAR2,
        o_flg_end_by_editable        OUT VARCHAR2,
        o_order_recurr_plan          OUT order_recurr_plan.id_order_recurr_plan%TYPE,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_order_recurr_plans table_number;
    
    BEGIN
        -- call set_other_order_recurr_option function
        IF NOT set_other_order_recurr_option(i_lang                       => i_lang,
                                             i_prof                       => i_prof,
                                             i_order_recurr_plans         => table_number(i_order_recurr_plan),
                                             i_regular_interval           => i_regular_interval,
                                             i_unit_meas_regular_interval => i_unit_meas_regular_interval,
                                             i_daily_executions           => i_daily_executions,
                                             i_predef_time_sched          => i_predef_time_sched,
                                             i_exec_time_parent_option    => i_exec_time_parent_option,
                                             i_exec_time_option           => i_exec_time_option,
                                             i_exec_time                  => i_exec_time,
                                             i_exec_time_offset           => i_exec_time_offset,
                                             i_unit_meas_exec_time_offset => i_unit_meas_exec_time_offset,
                                             i_flg_recurr_pattern         => i_flg_recurr_pattern,
                                             i_repeat_every               => i_repeat_every,
                                             i_flg_repeat_by              => i_flg_repeat_by,
                                             i_start_date                 => i_start_date,
                                             i_flg_end_by                 => i_flg_end_by,
                                             i_occurrences                => i_occurrences,
                                             i_duration                   => i_duration,
                                             i_unit_meas_duration         => i_unit_meas_duration,
                                             i_end_date                   => i_end_date,
                                             i_flg_week_day               => i_flg_week_day,
                                             i_flg_week                   => i_flg_week,
                                             i_month_day                  => i_month_day,
                                             i_month                      => i_month,
                                             i_flg_context                => i_flg_context,
                                             o_order_recurr_desc          => o_order_recurr_desc,
                                             o_order_recurr_option        => o_order_recurr_option,
                                             o_start_date                 => o_start_date,
                                             o_occurrences                => o_occurrences,
                                             o_duration                   => o_duration,
                                             o_unit_meas_duration         => o_unit_meas_duration,
                                             o_duration_desc              => o_duration_desc,
                                             o_end_date                   => o_end_date,
                                             o_flg_end_by_editable        => o_flg_end_by_editable,
                                             o_order_recurr_plans         => l_order_recurr_plans,
                                             o_error                      => o_error)
        
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.set_other_order_recurr_option function';
            RAISE e_user_exception;
        END IF;
    
        -- assign output variable
        o_order_recurr_plan := l_order_recurr_plans(1);
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_OTHER_ORDER_RECURR_OPTION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_other_order_recurr_option;

    FUNCTION set_other_order_recurr_option
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_order_recurr_plans         IN table_number,
        i_regular_interval           IN order_recurr_plan.regular_interval%TYPE,
        i_unit_meas_regular_interval IN order_recurr_plan.id_unit_meas_regular_interval%TYPE,
        i_daily_executions           IN order_recurr_plan.daily_executions%TYPE,
        i_predef_time_sched          IN table_number,
        i_exec_time_parent_option    IN table_number,
        i_exec_time_option           IN table_number,
        i_exec_time                  IN table_varchar,
        i_exec_time_offset           IN table_number,
        i_unit_meas_exec_time_offset IN table_number,
        i_flg_recurr_pattern         IN order_recurr_plan.flg_recurr_pattern%TYPE,
        i_repeat_every               IN order_recurr_plan.repeat_every%TYPE,
        i_flg_repeat_by              IN order_recurr_plan.flg_repeat_by%TYPE,
        i_start_date                 IN VARCHAR2,
        i_flg_end_by                 IN order_recurr_plan.flg_end_by%TYPE,
        i_occurrences                IN order_recurr_plan.occurrences%TYPE,
        i_duration                   IN order_recurr_plan.duration%TYPE,
        i_unit_meas_duration         IN order_recurr_plan.id_unit_meas_duration%TYPE,
        i_end_date                   IN VARCHAR2,
        i_flg_week_day               IN table_number,
        i_flg_week                   IN table_number,
        i_month_day                  IN table_number,
        i_month                      IN table_number,
        i_flg_context                IN VARCHAR2,
        o_order_recurr_desc          OUT VARCHAR2,
        o_order_recurr_option        OUT order_recurr_plan.id_order_recurr_option%TYPE,
        o_start_date                 OUT VARCHAR2,
        o_occurrences                OUT order_recurr_plan.occurrences%TYPE,
        o_duration                   OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration         OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_duration_desc              OUT VARCHAR2,
        o_end_date                   OUT VARCHAR2,
        o_flg_end_by_editable        OUT VARCHAR2,
        o_order_recurr_plans         OUT table_number,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_start_date_aux TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date_aux   TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        IF i_order_recurr_plans IS NULL
           OR i_order_recurr_plans.count = 0
        THEN
            g_error := 'order recurrence plan ids cannot be empty';
            RAISE e_user_exception;
        END IF;
    
        g_error              := 'Init set_other_order_recurr_option / i_start_date=' || i_start_date ||
                                ' i_occurrences=' || i_occurrences || ' i_duration=' || i_duration ||
                                ' i_unit_meas_duration=' || i_unit_meas_duration || ' i_end_date=' || i_end_date;
        o_order_recurr_plans := table_number();
        o_order_recurr_plans.extend(i_order_recurr_plans.count);
    
        l_start_date_aux := pk_date_utils.get_string_tstz(i_lang, i_prof, i_start_date, NULL);
        l_end_date_aux   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_end_date, NULL);
    
        IF i_flg_context = pk_order_recurrence_core.g_context_settings
        THEN
            l_start_date_aux := nvl(l_start_date_aux, current_timestamp);
        
            IF i_flg_end_by = pk_order_recurrence_core.g_flg_end_by_date
            THEN
                l_end_date_aux := nvl(l_end_date_aux, current_timestamp);
            END IF;
        END IF;
    
        g_error := 'FOR i IN 1 .. ' || i_order_recurr_plans.count;
        FOR i IN 1 .. i_order_recurr_plans.count
        LOOP
        
            -- call pk_order_recurrence_core.set_other_order_recurr_option function
            IF NOT pk_order_recurrence_core.set_other_order_recurr_option(i_lang                       => i_lang,
                                                                          i_prof                       => i_prof,
                                                                          i_order_recurr_plan          => i_order_recurr_plans(i),
                                                                          i_regular_interval           => i_regular_interval,
                                                                          i_unit_meas_regular_interval => i_unit_meas_regular_interval,
                                                                          i_daily_executions           => i_daily_executions,
                                                                          i_predef_time_sched          => i_predef_time_sched,
                                                                          i_exec_time_parent_option    => i_exec_time_parent_option,
                                                                          i_exec_time_option           => i_exec_time_option,
                                                                          i_exec_time                  => i_exec_time,
                                                                          i_exec_time_offset           => i_exec_time_offset,
                                                                          i_unit_meas_exec_time_offset => i_unit_meas_exec_time_offset,
                                                                          i_flg_recurr_pattern         => i_flg_recurr_pattern,
                                                                          i_repeat_every               => i_repeat_every,
                                                                          i_flg_repeat_by              => i_flg_repeat_by,
                                                                          i_start_date                 => l_start_date_aux,
                                                                          i_flg_end_by                 => i_flg_end_by,
                                                                          i_occurrences                => i_occurrences,
                                                                          i_duration                   => i_duration,
                                                                          i_unit_meas_duration         => i_unit_meas_duration,
                                                                          i_end_date                   => l_end_date_aux,
                                                                          i_flg_week_day               => i_flg_week_day,
                                                                          i_flg_week                   => i_flg_week,
                                                                          i_month_day                  => i_month_day,
                                                                          i_month                      => i_month,
                                                                          o_order_recurr_desc          => o_order_recurr_desc,
                                                                          o_start_date                 => l_start_date,
                                                                          o_occurrences                => o_occurrences,
                                                                          o_duration                   => o_duration,
                                                                          o_unit_meas_duration         => o_unit_meas_duration,
                                                                          o_end_date                   => l_end_date,
                                                                          o_flg_end_by_editable        => o_flg_end_by_editable,
                                                                          o_error                      => o_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.set_other_order_recurr_option function';
                RAISE e_user_exception;
            END IF;
        
            -- assign output variable
            o_order_recurr_plans(i) := i_order_recurr_plans(i);
        END LOOP;
    
        -- convert start date and end date to the format supported by the Flash layer
        o_start_date := pk_date_utils.date_send_tsz(i_lang, l_start_date, i_prof);
        o_end_date   := pk_date_utils.date_send_tsz(i_lang, l_end_date, i_prof);
    
        -- process duration description
        IF o_duration IS NOT NULL
        THEN
            o_duration_desc := o_duration || ' ' ||
                               pk_unit_measure.get_unit_measure_description(i_lang, i_prof, o_unit_meas_duration);
        END IF;
    
        -- assign remain output variables
        o_order_recurr_option := pk_order_recurrence_core.g_order_recurr_option_other;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_OTHER_ORDER_RECURR_OPTION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_other_order_recurr_option;

    FUNCTION set_order_recurr_other_option
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_order_recurr_plan          IN table_number,
        i_regular_interval           IN table_number,
        i_unit_meas_regular_interval IN table_number,
        i_daily_executions           IN table_number,
        i_predef_time_sched          IN table_table_number,
        i_exec_time_parent_option    IN table_table_number,
        i_exec_time_option           IN table_table_number,
        i_exec_time                  IN table_table_varchar,
        i_flg_recurr_pattern         IN table_varchar,
        i_repeat_every               IN table_number,
        i_flg_repeat_by              IN table_varchar,
        i_start_date                 IN table_varchar,
        i_flg_end_by                 IN table_varchar,
        i_occurrences                IN table_number,
        i_duration                   IN table_number,
        i_unit_meas_duration         IN table_number,
        i_end_date                   IN table_varchar,
        i_flg_week_day               IN table_table_number,
        i_flg_week                   IN table_table_number,
        i_month_day                  IN table_table_number,
        i_month                      IN table_table_number,
        i_flg_context                IN VARCHAR2,
        o_order_recurr_plan          OUT table_number,
        o_order_recurr_desc          OUT table_varchar,
        o_order_recurr_option        OUT table_number,
        o_start_date                 OUT table_varchar,
        o_occurrences                OUT table_number,
        o_duration                   OUT table_number,
        o_unit_meas_duration         OUT table_number,
        o_duration_desc              OUT table_varchar,
        o_end_date                   OUT table_varchar,
        o_flg_end_by_editable        OUT table_varchar,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_order_recurr_desc   VARCHAR2(1000 CHAR);
        l_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
        l_start_date          order_recurr_plan.start_date%TYPE;
        l_occurrences         order_recurr_plan.occurrences%TYPE;
        l_duration            order_recurr_plan.duration%TYPE;
        l_unit_meas_duration  order_recurr_plan.id_unit_meas_duration%TYPE;
        l_end_date            order_recurr_plan.end_date%TYPE;
        l_flg_end_by_editable VARCHAR2(1 CHAR);
    
        l_start_date_aux TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date_aux   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_exec_time_offset           table_number;
        l_unit_meas_exec_time_offset table_number;
    
    BEGIN
    
        IF i_order_recurr_plan IS NULL
           OR i_order_recurr_plan.count = 0
        THEN
            g_error := 'order recurrence plan ids cannot be empty';
            RAISE e_user_exception;
        END IF;
    
        o_order_recurr_plan   := table_number();
        o_order_recurr_desc   := table_varchar();
        o_order_recurr_option := table_number();
        o_start_date          := table_varchar();
        o_occurrences         := table_number();
        o_duration            := table_number();
        o_unit_meas_duration  := table_number();
        o_duration_desc       := table_varchar();
        o_end_date            := table_varchar();
        o_flg_end_by_editable := table_varchar();
    
        g_error := 'FOR i IN 1 .. ' || i_order_recurr_plan.count;
        FOR i IN 1 .. i_order_recurr_plan.count
        LOOP
        
            g_error := 'Init set_other_order_recurr_option / i_start_date=' || i_start_date(i) || ' i_occurrences=' ||
                      
                       i_occurrences(i) || ' i_duration=' || i_duration(i) || ' i_unit_meas_duration=' ||
                       i_unit_meas_duration(i) || ' i_end_date=' || i_end_date(i);
        
            l_start_date_aux := pk_date_utils.get_string_tstz(i_lang, i_prof, i_start_date(i), NULL);
            l_end_date_aux   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_end_date(i), NULL);
        
            IF i_flg_context = pk_order_recurrence_core.g_context_settings
            THEN
                l_start_date_aux := nvl(l_start_date_aux, current_timestamp);
            
                IF i_flg_end_by(i) = pk_order_recurrence_core.g_flg_end_by_date
                THEN
                    l_end_date_aux := nvl(l_end_date_aux, current_timestamp);
                END IF;
            END IF;
        
            l_exec_time_offset           := table_number();
            l_unit_meas_exec_time_offset := table_number();
            IF i_exec_time(i).count > 0
            THEN
                FOR j IN i_exec_time(i).first .. i_exec_time(i).last
                LOOP
                    l_exec_time_offset.extend;
                    l_exec_time_offset(j) := NULL;
                
                    l_unit_meas_exec_time_offset.extend;
                    l_unit_meas_exec_time_offset(j) := NULL;
                END LOOP;
            END IF;
        
            -- call pk_order_recurrence_core.set_other_order_recurr_option function
            IF NOT pk_order_recurrence_core.set_other_order_recurr_option(i_lang                       => i_lang,
                                                                          i_prof                       => i_prof,
                                                                          i_order_recurr_plan          => i_order_recurr_plan(i),
                                                                          i_regular_interval           => i_regular_interval(i),
                                                                          i_unit_meas_regular_interval => i_unit_meas_regular_interval(i),
                                                                          i_daily_executions           => i_daily_executions(i),
                                                                          i_predef_time_sched          => i_predef_time_sched(i),
                                                                          i_exec_time_parent_option    => i_exec_time_parent_option(i),
                                                                          i_exec_time_option           => i_exec_time_option(i),
                                                                          i_exec_time                  => i_exec_time(i),
                                                                          i_exec_time_offset           => l_exec_time_offset,
                                                                          i_unit_meas_exec_time_offset => l_unit_meas_exec_time_offset,
                                                                          i_flg_recurr_pattern         => i_flg_recurr_pattern(i),
                                                                          i_repeat_every               => i_repeat_every(i),
                                                                          i_flg_repeat_by              => i_flg_repeat_by(i),
                                                                          i_start_date                 => l_start_date_aux,
                                                                          i_flg_end_by                 => i_flg_end_by(i),
                                                                          i_occurrences                => i_occurrences(i),
                                                                          i_duration                   => i_duration(i),
                                                                          i_unit_meas_duration         => i_unit_meas_duration(i),
                                                                          i_end_date                   => l_end_date_aux,
                                                                          i_flg_week_day               => i_flg_week_day(i),
                                                                          i_flg_week                   => i_flg_week(i),
                                                                          i_month_day                  => i_month_day(i),
                                                                          i_month                      => i_month(i),
                                                                          o_order_recurr_desc          => l_order_recurr_desc,
                                                                          o_start_date                 => l_start_date,
                                                                          o_occurrences                => l_occurrences,
                                                                          o_duration                   => l_duration,
                                                                          o_unit_meas_duration         => l_unit_meas_duration,
                                                                          o_end_date                   => l_end_date,
                                                                          o_flg_end_by_editable        => l_flg_end_by_editable,
                                                                          o_error                      => o_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.set_other_order_recurr_option function';
                RAISE e_user_exception;
            END IF;
        
            o_order_recurr_desc.extend;
            o_order_recurr_option.extend;
            o_start_date.extend;
            o_occurrences.extend;
            o_duration.extend;
            o_unit_meas_duration.extend;
            o_duration_desc.extend;
            o_end_date.extend;
            o_flg_end_by_editable.extend;
            o_order_recurr_plan.extend;
        
            -- assign output variable
            o_order_recurr_plan(i) := i_order_recurr_plan(i);
        
            o_order_recurr_desc(i) := l_order_recurr_desc;
            o_order_recurr_option(i) := nvl(l_order_recurr_option, pk_order_recurrence_core.g_order_recurr_option_other);
        
            IF i_flg_context = pk_order_recurrence_core.g_context_patient
            THEN
                o_start_date(i) := pk_date_utils.date_send_tsz(i_lang, l_start_date, i_prof);
                o_end_date(i) := pk_date_utils.date_send_tsz(i_lang, l_end_date, i_prof);
            ELSE
                o_start_date(i) := NULL;
                o_end_date(i) := NULL;
            END IF;
        
            o_flg_end_by_editable(i) := l_flg_end_by_editable;
        
            o_occurrences(i) := l_occurrences;
            o_duration(i) := l_duration;
            o_unit_meas_duration(i) := l_unit_meas_duration;
        
            IF l_duration IS NOT NULL
            THEN
                o_duration_desc(i) := l_duration || ' ' ||
                                      pk_unit_measure.get_unit_measure_description(i_lang, i_prof, l_unit_meas_duration);
            END IF;
        
        END LOOP;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ORDER_RECURR_OTHER_OPTION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_order_recurr_other_option;

    FUNCTION set_order_recurr_other_option
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_order_recurr_plan    IN table_number,
        i_tbl_ds_internal_name IN table_varchar,
        i_tbl_real_val         IN table_table_varchar,
        i_value_mea            IN table_table_varchar,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_regular_interval        table_number := table_number();
        l_tbl_unit_meas_regular_int   table_number := table_number();
        l_tbl_daily_executions        table_number := table_number();
        l_tbl_predef_time_sched       table_table_number := table_table_number();
        l_tbl_exec_time_parent_option table_table_number := table_table_number();
        l_tbl_exec_time_option        table_table_number := table_table_number();
        l_tbl_exec_time               table_table_varchar := table_table_varchar();
        l_tbl_flg_recurr_pattern      table_varchar := table_varchar();
        l_tbl_repeat_every            table_number := table_number();
        l_tbl_flg_repeat_by           table_varchar := table_varchar();
        l_tbl_start_date              table_varchar := table_varchar();
        l_tbl_flg_end_by              table_varchar := table_varchar();
        l_tbl_occurrences             table_number := table_number();
        l_tbl_duration                table_number := table_number();
        l_tbl_unit_meas_duration      table_number := table_number();
        l_tbl_end_date                table_varchar := table_varchar();
        l_tbl_flg_week_day            table_table_number := table_table_number();
        l_tbl_flg_week                table_table_number := table_table_number();
        l_tbl_month_day               table_table_number := table_table_number();
        l_tbl_month                   table_table_number := table_table_number();
        l_flg_context                 VARCHAR2(1) := 'P';
    
        l_order_recurr_desc   VARCHAR2(1000 CHAR);
        l_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
        l_start_date          order_recurr_plan.start_date%TYPE;
        l_occurrences         order_recurr_plan.occurrences%TYPE;
        l_duration            order_recurr_plan.duration%TYPE;
        l_unit_meas_duration  order_recurr_plan.id_unit_meas_duration%TYPE;
        l_end_date            order_recurr_plan.end_date%TYPE;
        l_flg_end_by_editable VARCHAR2(1 CHAR);
    
        l_start_date_aux TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date_aux   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_exec_time_offset           table_number;
        l_unit_meas_exec_time_offset table_number;
    
        l_tbl_aux_num table_number := table_number();
        l_tbl_aux_chr table_varchar := table_varchar();
    
        l_num_daily_executions_aux PLS_INTEGER := 0;
    
        o_order_recurr_plan   table_number;
        o_order_recurr_desc   table_varchar;
        o_order_recurr_option table_number;
        o_start_date          table_varchar;
        o_occurrences         table_number;
        o_duration            table_number;
        o_unit_meas_duration  table_number;
        o_duration_desc       table_varchar;
        o_end_date            table_varchar;
        o_flg_end_by_editable table_varchar;
    
    BEGIN
    
        IF i_order_recurr_plan IS NULL
           OR i_order_recurr_plan.count = 0
        THEN
            g_error := 'order recurrence plan ids cannot be empty';
            RAISE e_user_exception;
        END IF;
    
        --INIT (unused parameters)
        FOR i IN i_order_recurr_plan.first .. i_order_recurr_plan.last
        LOOP
            l_tbl_flg_repeat_by.extend();
            l_tbl_flg_repeat_by(i) := NULL;
            l_tbl_flg_week_day.extend();
            l_tbl_flg_week_day(i) := table_number(NULL);
            l_tbl_flg_week.extend();
            l_tbl_flg_week(i) := table_number(NULL);
            l_tbl_month_day.extend();
            l_tbl_month_day(i) := table_number(NULL);
            l_tbl_month.extend();
            l_tbl_month(i) := table_number(NULL);
        END LOOP;
    
        o_order_recurr_plan   := table_number();
        o_order_recurr_desc   := table_varchar();
        o_order_recurr_option := table_number();
        o_start_date          := table_varchar();
        o_occurrences         := table_number();
        o_duration            := table_number();
        o_unit_meas_duration  := table_number();
        o_duration_desc       := table_varchar();
        o_end_date            := table_varchar();
        o_flg_end_by_editable := table_varchar();
    
        FOR i IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
        LOOP
            IF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_regular_intervals
            THEN
                FOR j IN i_order_recurr_plan.first .. i_order_recurr_plan.last
                LOOP
                    l_tbl_regular_interval.extend();
                    l_tbl_regular_interval(l_tbl_regular_interval.count) := to_number(i_tbl_real_val(i) (j));
                
                    l_tbl_unit_meas_regular_int.extend();
                    l_tbl_unit_meas_regular_int(l_tbl_unit_meas_regular_int.count) := to_number(i_value_mea(i) (j));
                END LOOP;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_daily_executions
            THEN
                FOR j IN i_order_recurr_plan.first .. i_order_recurr_plan.last
                LOOP
                    l_tbl_daily_executions.extend();
                    l_tbl_daily_executions(l_tbl_daily_executions.count) := to_number(i_tbl_real_val(i) (j));
                END LOOP;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_time_schedule
            THEN
                l_tbl_aux_num := table_number();
            
                FOR j IN i_order_recurr_plan.first .. i_order_recurr_plan.last
                LOOP
                    l_tbl_aux_num.extend();
                    l_tbl_aux_num(l_tbl_aux_num.count) := to_number(i_tbl_real_val(i) (j));
                END LOOP;
            
                FOR j IN i_order_recurr_plan.first .. i_order_recurr_plan.last
                LOOP
                    l_tbl_predef_time_sched.extend();
                    l_tbl_predef_time_sched(l_tbl_predef_time_sched.count) := table_number(l_tbl_aux_num(j));
                
                    FOR k IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
                    LOOP
                        IF i_tbl_ds_internal_name(k) = pk_orders_constant.g_ds_daily_executions
                        THEN
                            l_num_daily_executions_aux := i_tbl_real_val(k) (j);
                            EXIT;
                        END IF;
                    END LOOP;
                
                    IF l_num_daily_executions_aux = 1
                       OR l_num_daily_executions_aux IS NULL
                    THEN
                        l_tbl_exec_time_parent_option.extend();
                        l_tbl_exec_time_option.extend();
                    
                        l_tbl_exec_time_parent_option(l_tbl_exec_time_parent_option.count) := table_number(l_tbl_aux_num(j));
                        l_tbl_exec_time_option(l_tbl_exec_time_option.count) := table_number(l_tbl_aux_num(j));
                    END IF;
                END LOOP;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_recurrence_pattern
            THEN
                FOR j IN i_order_recurr_plan.first .. i_order_recurr_plan.last
                LOOP
                    l_tbl_flg_recurr_pattern.extend();
                    l_tbl_flg_recurr_pattern(l_tbl_flg_recurr_pattern.count) := coalesce(i_tbl_real_val(i) (j), '0');
                END LOOP;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_repeat_every
            THEN
                FOR j IN i_order_recurr_plan.first .. i_order_recurr_plan.last
                LOOP
                    l_tbl_repeat_every.extend();
                    l_tbl_repeat_every(l_tbl_repeat_every.count) := i_tbl_real_val(i) (j);
                END LOOP;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_start_date
            THEN
                FOR j IN i_order_recurr_plan.first .. i_order_recurr_plan.last
                LOOP
                    l_tbl_start_date.extend();
                    l_tbl_start_date(l_tbl_start_date.count) := i_tbl_real_val(i) (j);
                END LOOP;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_end_based
            THEN
                FOR j IN i_order_recurr_plan.first .. i_order_recurr_plan.last
                LOOP
                    l_tbl_flg_end_by.extend();
                    l_tbl_flg_end_by(l_tbl_flg_end_by.count) := i_tbl_real_val(i) (j);
                END LOOP;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_end_after_n
            THEN
                FOR j IN i_order_recurr_plan.first .. i_order_recurr_plan.last
                LOOP
                    -- l_tbl_occurrences.extend();
                
                    l_tbl_duration.extend();
                    l_tbl_duration(l_tbl_duration.count) := to_number(i_tbl_real_val(i) (j));
                
                    l_tbl_unit_meas_duration.extend();
                    l_tbl_unit_meas_duration(l_tbl_unit_meas_duration.count) := to_number(i_value_mea(i) (j));
                END LOOP;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_end_after_occurrences
            THEN
                FOR j IN i_order_recurr_plan.first .. i_order_recurr_plan.last
                LOOP
                    l_tbl_occurrences.extend();
                    l_tbl_occurrences(l_tbl_occurrences.count) := to_number(i_tbl_real_val(i) (j));
                
                -- l_tbl_duration.extend();
                -- l_tbl_unit_meas_duration.extend();
                END LOOP;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_end_after
            THEN
                FOR j IN i_order_recurr_plan.first .. i_order_recurr_plan.last
                LOOP
                    l_tbl_end_date.extend();
                    l_tbl_end_date(l_tbl_end_date.count) := i_tbl_real_val(i) (1);
                
                --l_tbl_occurrences.extend();
                -- l_tbl_duration.extend();
                -- l_tbl_unit_meas_duration.extend();
                END LOOP;
            END IF;
        END LOOP;
    
        --'Exec time' parsing
        g_error := 'Exec time parsing';
        FOR i IN i_order_recurr_plan.first .. i_order_recurr_plan.last
        LOOP
            l_tbl_exec_time.extend();
        
            l_tbl_aux_chr := table_varchar();
        
            FOR j IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
            LOOP
                IF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_exact_time
                THEN
                    l_tbl_aux_chr.extend();
                    l_tbl_aux_chr(l_tbl_aux_chr.count) := substr(i_tbl_real_val(j) (i), 9, 4);
                    EXIT;
                END IF;
            END LOOP;
        
            FOR j IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
            LOOP
                IF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_exact_time_02
                   AND l_tbl_daily_executions(i) >= 2
                THEN
                    l_tbl_aux_chr.extend();
                    l_tbl_aux_chr(l_tbl_aux_chr.count) := substr(i_tbl_real_val(j) (i), 9, 4);
                    EXIT;
                END IF;
            END LOOP;
        
            FOR j IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
            LOOP
                IF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_exact_time_03
                   AND l_tbl_daily_executions(i) >= 3
                THEN
                    l_tbl_aux_chr.extend();
                    l_tbl_aux_chr(l_tbl_aux_chr.count) := substr(i_tbl_real_val(j) (i), 9, 4);
                    EXIT;
                END IF;
            END LOOP;
        
            FOR j IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
            LOOP
                IF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_exact_time_04
                   AND l_tbl_daily_executions(i) >= 4
                THEN
                    l_tbl_aux_chr.extend();
                    l_tbl_aux_chr(l_tbl_aux_chr.count) := substr(i_tbl_real_val(j) (i), 9, 4);
                    EXIT;
                END IF;
            END LOOP;
        
            FOR j IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
            LOOP
                IF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_exact_time_05
                   AND l_tbl_daily_executions(i) >= 5
                THEN
                    l_tbl_aux_chr.extend();
                    l_tbl_aux_chr(l_tbl_aux_chr.count) := substr(i_tbl_real_val(j) (i), 9, 4);
                    EXIT;
                END IF;
            END LOOP;
        
            FOR j IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
            LOOP
                IF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_exact_time_06
                   AND l_tbl_daily_executions(i) >= 6
                THEN
                    l_tbl_aux_chr.extend();
                    l_tbl_aux_chr(l_tbl_aux_chr.count) := substr(i_tbl_real_val(j) (i), 9, 4);
                    EXIT;
                END IF;
            END LOOP;
        
            FOR j IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
            LOOP
                IF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_exact_time_07
                   AND l_tbl_daily_executions(i) >= 7
                THEN
                    l_tbl_aux_chr.extend();
                    l_tbl_aux_chr(l_tbl_aux_chr.count) := substr(i_tbl_real_val(j) (i), 9, 4);
                    EXIT;
                END IF;
            END LOOP;
        
            FOR j IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
            LOOP
                IF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_exact_time_08
                   AND l_tbl_daily_executions(i) >= 8
                THEN
                    l_tbl_aux_chr.extend();
                    l_tbl_aux_chr(l_tbl_aux_chr.count) := substr(i_tbl_real_val(j) (i), 9, 4);
                    EXIT;
                END IF;
            END LOOP;
        
            FOR j IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
            LOOP
                IF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_exact_time_09
                   AND l_tbl_daily_executions(i) >= 9
                THEN
                    l_tbl_aux_chr.extend();
                    l_tbl_aux_chr(l_tbl_aux_chr.count) := substr(i_tbl_real_val(j) (i), 9, 4);
                    EXIT;
                END IF;
            END LOOP;
        
            l_tbl_exec_time(i) := l_tbl_aux_chr;
            IF l_tbl_daily_executions(i) > 1
            THEN
                l_tbl_exec_time_parent_option.extend();
                l_tbl_exec_time_option.extend();
            
                l_tbl_exec_time_parent_option(i) := table_number();
                l_tbl_exec_time_option(i) := table_number();
            
                FOR j IN l_tbl_aux_chr.first .. l_tbl_aux_chr.last
                LOOP
                    l_tbl_exec_time_parent_option(i).extend();
                    l_tbl_exec_time_option(i).extend();
                
                    l_tbl_exec_time_parent_option(i)(l_tbl_exec_time_parent_option(i).count) := NULL;
                    l_tbl_exec_time_option(i)(l_tbl_exec_time_option(i).count) := NULL;
                END LOOP;
            END IF;
        END LOOP;
    
        g_error := 'FOR i IN 1 .. ' || i_order_recurr_plan.count;
        FOR i IN i_order_recurr_plan.first .. i_order_recurr_plan.last
        LOOP
        
            g_error := 'Init set_other_order_recurr_option / i_start_date=' || l_tbl_start_date(i) || ' i_occurrences=' ||
                      
                       l_tbl_occurrences(i) || ' i_duration=' || l_tbl_duration(i) || ' i_unit_meas_duration=' ||
                       l_tbl_unit_meas_duration(i) || ' i_end_date=' || l_tbl_end_date(i);
        
            l_start_date_aux := pk_date_utils.get_string_tstz(i_lang, i_prof, l_tbl_start_date(i), NULL);
            l_end_date_aux   := pk_date_utils.get_string_tstz(i_lang, i_prof, l_tbl_end_date(i), NULL);
        
            IF l_flg_context = pk_order_recurrence_core.g_context_settings
            THEN
                l_start_date_aux := nvl(l_start_date_aux, current_timestamp);
            
                IF l_tbl_flg_end_by(i) = pk_order_recurrence_core.g_flg_end_by_date
                THEN
                    l_end_date_aux := nvl(l_end_date_aux, current_timestamp);
                END IF;
            END IF;
        
            l_exec_time_offset           := table_number();
            l_unit_meas_exec_time_offset := table_number();
        
            IF l_tbl_exec_time(i).count > 0
            THEN
                FOR j IN l_tbl_exec_time(i).first .. l_tbl_exec_time(i).last
                LOOP
                    l_exec_time_offset.extend;
                    l_exec_time_offset(j) := NULL;
                    l_unit_meas_exec_time_offset.extend;
                    l_unit_meas_exec_time_offset(j) := NULL;
                END LOOP;
            END IF;
        
            -- call pk_order_recurrence_core.set_other_order_recurr_option function
            IF NOT pk_order_recurrence_core.set_other_order_recurr_option(i_lang                       => i_lang,
                                                                          i_prof                       => i_prof,
                                                                          i_order_recurr_plan          => i_order_recurr_plan(i),
                                                                          i_regular_interval           => l_tbl_regular_interval(i),
                                                                          i_unit_meas_regular_interval => l_tbl_unit_meas_regular_int(i),
                                                                          i_daily_executions           => l_tbl_daily_executions(i),
                                                                          i_predef_time_sched          => l_tbl_predef_time_sched(i),
                                                                          i_exec_time_parent_option    => l_tbl_exec_time_parent_option(i),
                                                                          i_exec_time_option           => l_tbl_exec_time_option(i),
                                                                          i_exec_time                  => l_tbl_exec_time(i),
                                                                          i_exec_time_offset           => l_exec_time_offset,
                                                                          i_unit_meas_exec_time_offset => l_unit_meas_exec_time_offset,
                                                                          i_flg_recurr_pattern         => l_tbl_flg_recurr_pattern(i),
                                                                          i_repeat_every               => l_tbl_repeat_every(i),
                                                                          i_flg_repeat_by              => l_tbl_flg_repeat_by(i),
                                                                          i_start_date                 => l_start_date_aux,
                                                                          i_flg_end_by                 => l_tbl_flg_end_by(i),
                                                                          i_occurrences                => l_tbl_occurrences(i),
                                                                          i_duration                   => l_tbl_duration(i),
                                                                          i_unit_meas_duration         => l_tbl_unit_meas_duration(i),
                                                                          i_end_date                   => l_end_date_aux,
                                                                          i_flg_week_day               => l_tbl_flg_week_day(i),
                                                                          i_flg_week                   => l_tbl_flg_week(i),
                                                                          i_month_day                  => l_tbl_month_day(i),
                                                                          i_month                      => l_tbl_month(i),
                                                                          o_order_recurr_desc          => l_order_recurr_desc,
                                                                          o_start_date                 => l_start_date,
                                                                          o_occurrences                => l_occurrences,
                                                                          o_duration                   => l_duration,
                                                                          o_unit_meas_duration         => l_unit_meas_duration,
                                                                          o_end_date                   => l_end_date,
                                                                          o_flg_end_by_editable        => l_flg_end_by_editable,
                                                                          o_error                      => o_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.set_other_order_recurr_option function';
                RAISE e_user_exception;
            END IF;
        
            o_order_recurr_desc.extend;
            o_order_recurr_option.extend;
            o_start_date.extend;
            o_occurrences.extend;
            o_duration.extend;
            o_unit_meas_duration.extend;
            o_duration_desc.extend;
            o_end_date.extend;
            o_flg_end_by_editable.extend;
            o_order_recurr_plan.extend;
        
            -- assign output variable
            o_order_recurr_plan(i) := i_order_recurr_plan(i);
        
            o_order_recurr_desc(i) := l_order_recurr_desc;
            o_order_recurr_option(i) := nvl(l_order_recurr_option, pk_order_recurrence_core.g_order_recurr_option_other);
        
            IF l_flg_context = pk_order_recurrence_core.g_context_patient
            THEN
                o_start_date(i) := pk_date_utils.date_send_tsz(i_lang, l_start_date, i_prof);
                o_end_date(i) := pk_date_utils.date_send_tsz(i_lang, l_end_date, i_prof);
            ELSE
                o_start_date(i) := NULL;
                o_end_date(i) := NULL;
            END IF;
        
            o_flg_end_by_editable(i) := l_flg_end_by_editable;
        
            o_occurrences(i) := l_occurrences;
            o_duration(i) := l_duration;
            o_unit_meas_duration(i) := l_unit_meas_duration;
        
            IF l_duration IS NOT NULL
            THEN
                o_duration_desc(i) := l_duration || ' ' ||
                                      pk_unit_measure.get_unit_measure_description(i_lang, i_prof, l_unit_meas_duration);
            END IF;
        
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
                                              'SET_ORDER_RECURR_OTHER_OPTION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_order_recurr_other_option;

    FUNCTION set_order_recurr_plan
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_order_recurr_plan       IN order_recurr_plan.id_order_recurr_plan%TYPE,
        o_order_recurr_option     OUT order_recurr_plan.id_order_recurr_option%TYPE,
        o_final_order_recurr_plan OUT order_recurr_plan.id_order_recurr_plan%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- call pk_order_recurrence_core.set_order_recurr_plan function
        IF NOT pk_order_recurrence_core.set_order_recurr_plan(i_lang                    => i_lang,
                                                              i_prof                    => i_prof,
                                                              i_order_recurr_plan       => i_order_recurr_plan,
                                                              o_order_recurr_option     => o_order_recurr_option,
                                                              o_final_order_recurr_plan => o_final_order_recurr_plan,
                                                              o_error                   => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.set_order_recurr_plan function';
            RAISE e_user_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ORDER_RECURR_PLAN',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_order_recurr_plan;

    FUNCTION cancel_order_recurr_plan
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- call pk_order_recurrence_core.cancel_order_recurr_plan function
        IF NOT pk_order_recurrence_core.cancel_order_recurr_plan(i_lang              => i_lang,
                                                                 i_prof              => i_prof,
                                                                 i_order_recurr_plan => i_order_recurr_plan,
                                                                 o_error             => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.cancel_order_recurr_plan function';
            RAISE e_user_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_ORDER_RECURR_PLAN',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_order_recurr_plan;

    FUNCTION cancel_order_recurr_plan
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_order_recurr_plans IN table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF i_order_recurr_plans IS NULL
           OR i_order_recurr_plans.count = 0
        THEN
            g_error := 'order recurrence plan ids cannot be empty';
            RAISE e_user_exception;
        END IF;
    
        FOR i IN 1 .. i_order_recurr_plans.count
        LOOP
        
            -- call pk_order_recurrence_core.cancel_order_recurr_plan function
            g_error := 'Call pk_order_recurrence_core.cancel_order_recurr_plan / i_order_recurr_plan=' ||
                       i_order_recurr_plans(i);
            IF NOT pk_order_recurrence_core.cancel_order_recurr_plan(i_lang              => i_lang,
                                                                     i_prof              => i_prof,
                                                                     i_order_recurr_plan => i_order_recurr_plans(i),
                                                                     o_error             => o_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.cancel_order_recurr_plan function';
                RAISE e_user_exception;
            END IF;
        
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_ORDER_RECURR_PLAN',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_order_recurr_plan;

    FUNCTION get_other_order_recurr_option
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_order_recurr_plan          IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_flg_context                IN VARCHAR2,
        o_regular_interval           OUT order_recurr_plan.regular_interval%TYPE,
        o_unit_meas_regular_interval OUT order_recurr_plan.id_unit_meas_regular_interval%TYPE,
        o_regular_interval_desc      OUT VARCHAR2,
        o_daily_executions           OUT order_recurr_plan.daily_executions%TYPE,
        o_predef_time_sched          OUT table_number,
        o_predef_time_sched_desc     OUT VARCHAR2,
        o_exec_times                 OUT pk_types.cursor_type,
        o_flg_recurr_pattern         OUT order_recurr_plan.flg_recurr_pattern%TYPE,
        o_recurr_pattern_desc        OUT VARCHAR2,
        o_repeat_every               OUT order_recurr_plan.repeat_every%TYPE,
        o_unit_meas_repeat_every     OUT unit_measure.id_unit_measure%TYPE,
        o_repeat_every_desc          OUT VARCHAR2,
        o_flg_repeat_by              OUT order_recurr_plan.flg_repeat_by%TYPE,
        o_repeat_by_desc             OUT VARCHAR2,
        o_start_date                 OUT VARCHAR2,
        o_flg_end_by                 OUT order_recurr_plan.flg_end_by%TYPE,
        o_end_by_desc                OUT VARCHAR2,
        o_occurrences                OUT order_recurr_plan.occurrences%TYPE,
        o_duration                   OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration         OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_end_date                   OUT VARCHAR2,
        o_end_after_desc             OUT VARCHAR2,
        o_flg_week_day               OUT table_number,
        o_week_day_desc              OUT VARCHAR2,
        o_flg_week                   OUT table_number,
        o_week_desc                  OUT VARCHAR2,
        o_month_day                  OUT table_number,
        o_month                      OUT table_number,
        o_month_desc                 OUT VARCHAR2,
        o_flg_regular_interval_edit  OUT VARCHAR2,
        o_flg_daily_executions_edit  OUT VARCHAR2,
        o_flg_predef_time_sched_edit OUT VARCHAR2,
        o_flg_exec_time_edit         OUT VARCHAR2,
        o_flg_repeat_every_edit      OUT VARCHAR2,
        o_flg_repeat_by_edit         OUT VARCHAR2,
        o_flg_start_date_edit        OUT VARCHAR2,
        o_flg_end_by_edit            OUT VARCHAR2,
        o_flg_end_after_edit         OUT VARCHAR2,
        o_flg_week_day_edit          OUT VARCHAR2,
        o_flg_week_edit              OUT VARCHAR2,
        o_flg_month_day_edit         OUT VARCHAR2,
        o_flg_month_edit             OUT VARCHAR2,
        o_flg_ok_avail               OUT VARCHAR2,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- call get_other_order_recurr_option function
        IF NOT get_other_order_recurr_option(i_lang                       => i_lang,
                                             i_prof                       => i_prof,
                                             i_order_recurr_plans         => table_number(i_order_recurr_plan),
                                             i_flg_context                => i_flg_context,
                                             o_regular_interval           => o_regular_interval,
                                             o_unit_meas_regular_interval => o_unit_meas_regular_interval,
                                             o_regular_interval_desc      => o_regular_interval_desc,
                                             o_daily_executions           => o_daily_executions,
                                             o_predef_time_sched          => o_predef_time_sched,
                                             o_predef_time_sched_desc     => o_predef_time_sched_desc,
                                             o_exec_times                 => o_exec_times,
                                             o_flg_recurr_pattern         => o_flg_recurr_pattern,
                                             o_recurr_pattern_desc        => o_recurr_pattern_desc,
                                             o_repeat_every               => o_repeat_every,
                                             o_unit_meas_repeat_every     => o_unit_meas_repeat_every,
                                             o_repeat_every_desc          => o_repeat_every_desc,
                                             o_flg_repeat_by              => o_flg_repeat_by,
                                             o_repeat_by_desc             => o_repeat_by_desc,
                                             o_start_date                 => o_start_date,
                                             o_flg_end_by                 => o_flg_end_by,
                                             o_end_by_desc                => o_end_by_desc,
                                             o_occurrences                => o_occurrences,
                                             o_duration                   => o_duration,
                                             o_unit_meas_duration         => o_unit_meas_duration,
                                             o_end_date                   => o_end_date,
                                             o_end_after_desc             => o_end_after_desc,
                                             o_flg_week_day               => o_flg_week_day,
                                             o_week_day_desc              => o_week_day_desc,
                                             o_flg_week                   => o_flg_week,
                                             o_week_desc                  => o_week_desc,
                                             o_month_day                  => o_month_day,
                                             o_month                      => o_month,
                                             o_month_desc                 => o_month_desc,
                                             o_flg_regular_interval_edit  => o_flg_regular_interval_edit,
                                             o_flg_daily_executions_edit  => o_flg_daily_executions_edit,
                                             o_flg_predef_time_sched_edit => o_flg_predef_time_sched_edit,
                                             o_flg_exec_time_edit         => o_flg_exec_time_edit,
                                             o_flg_repeat_every_edit      => o_flg_repeat_every_edit,
                                             o_flg_repeat_by_edit         => o_flg_repeat_by_edit,
                                             o_flg_start_date_edit        => o_flg_start_date_edit,
                                             o_flg_end_by_edit            => o_flg_end_by_edit,
                                             o_flg_end_after_edit         => o_flg_end_after_edit,
                                             o_flg_week_day_edit          => o_flg_week_day_edit,
                                             o_flg_week_edit              => o_flg_week_edit,
                                             o_flg_month_day_edit         => o_flg_month_day_edit,
                                             o_flg_month_edit             => o_flg_month_edit,
                                             o_flg_ok_avail               => o_flg_ok_avail,
                                             o_error                      => o_error)
        THEN
            g_error := 'error found while calling get_other_order_recurr_option function';
            RAISE e_user_exception;
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
                                              'GET_OTHER_ORDER_RECURR_OPTION',
                                              o_error);
            pk_types.open_my_cursor(o_exec_times);
            RETURN FALSE;
    END get_other_order_recurr_option;

    FUNCTION get_other_order_recurr_option
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_order_recurr_plans         IN table_number,
        i_flg_context                IN VARCHAR2,
        o_regular_interval           OUT order_recurr_plan.regular_interval%TYPE,
        o_unit_meas_regular_interval OUT order_recurr_plan.id_unit_meas_regular_interval%TYPE,
        o_regular_interval_desc      OUT VARCHAR2,
        o_daily_executions           OUT order_recurr_plan.daily_executions%TYPE,
        o_predef_time_sched          OUT table_number,
        o_predef_time_sched_desc     OUT VARCHAR2,
        o_exec_times                 OUT pk_types.cursor_type,
        o_flg_recurr_pattern         OUT order_recurr_plan.flg_recurr_pattern%TYPE,
        o_recurr_pattern_desc        OUT VARCHAR2,
        o_repeat_every               OUT order_recurr_plan.repeat_every%TYPE,
        o_unit_meas_repeat_every     OUT unit_measure.id_unit_measure%TYPE,
        o_repeat_every_desc          OUT VARCHAR2,
        o_flg_repeat_by              OUT order_recurr_plan.flg_repeat_by%TYPE,
        o_repeat_by_desc             OUT VARCHAR2,
        o_start_date                 OUT VARCHAR2,
        o_flg_end_by                 OUT order_recurr_plan.flg_end_by%TYPE,
        o_end_by_desc                OUT VARCHAR2,
        o_occurrences                OUT order_recurr_plan.occurrences%TYPE,
        o_duration                   OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration         OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_end_date                   OUT VARCHAR2,
        o_end_after_desc             OUT VARCHAR2,
        o_flg_week_day               OUT table_number,
        o_week_day_desc              OUT VARCHAR2,
        o_flg_week                   OUT table_number,
        o_week_desc                  OUT VARCHAR2,
        o_month_day                  OUT table_number,
        o_month                      OUT table_number,
        o_month_desc                 OUT VARCHAR2,
        o_flg_regular_interval_edit  OUT VARCHAR2,
        o_flg_daily_executions_edit  OUT VARCHAR2,
        o_flg_predef_time_sched_edit OUT VARCHAR2,
        o_flg_exec_time_edit         OUT VARCHAR2,
        o_flg_repeat_every_edit      OUT VARCHAR2,
        o_flg_repeat_by_edit         OUT VARCHAR2,
        o_flg_start_date_edit        OUT VARCHAR2,
        o_flg_end_by_edit            OUT VARCHAR2,
        o_flg_end_after_edit         OUT VARCHAR2,
        o_flg_week_day_edit          OUT VARCHAR2,
        o_flg_week_edit              OUT VARCHAR2,
        o_flg_month_day_edit         OUT VARCHAR2,
        o_flg_month_edit             OUT VARCHAR2,
        o_flg_ok_avail               OUT VARCHAR2,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- auxiliary local variables
        l_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_predef_time_sched_desc table_varchar;
        l_week_day_desc          table_varchar;
        l_week_desc              table_varchar;
        l_month_desc             table_varchar;
    
        l_exec_times t_tbl_recurr_exec_times;
    
    BEGIN
    
        IF i_order_recurr_plans IS NULL
           OR i_order_recurr_plans.count = 0
        THEN
            g_error := 'order recurrence plan ids cannot be empty';
            RAISE e_user_exception;
        END IF;
    
        -- call pk_order_recurrence_core.get_other_order_recurr_option function
        IF NOT pk_order_recurrence_core.get_other_order_recurr_option(i_lang                       => i_lang,
                                                                      i_prof                       => i_prof,
                                                                      i_order_recurr_plan          => i_order_recurr_plans(1),
                                                                      i_flg_context                => i_flg_context,
                                                                      o_regular_interval           => o_regular_interval,
                                                                      o_unit_meas_regular_interval => o_unit_meas_regular_interval,
                                                                      o_daily_executions           => o_daily_executions,
                                                                      o_predef_time_sched          => o_predef_time_sched,
                                                                      o_exec_times                 => l_exec_times,
                                                                      o_flg_recurr_pattern         => o_flg_recurr_pattern,
                                                                      o_repeat_every               => o_repeat_every,
                                                                      o_unit_meas_repeat_every     => o_unit_meas_repeat_every,
                                                                      o_flg_repeat_by              => o_flg_repeat_by,
                                                                      o_start_date                 => l_start_date,
                                                                      o_flg_end_by                 => o_flg_end_by,
                                                                      o_occurrences                => o_occurrences,
                                                                      o_duration                   => o_duration,
                                                                      o_unit_meas_duration         => o_unit_meas_duration,
                                                                      o_end_date                   => l_end_date,
                                                                      o_flg_week_day               => o_flg_week_day,
                                                                      o_flg_week                   => o_flg_week,
                                                                      o_month_day                  => o_month_day,
                                                                      o_month                      => o_month,
                                                                      o_flg_regular_interval_edit  => o_flg_regular_interval_edit,
                                                                      o_flg_daily_executions_edit  => o_flg_daily_executions_edit,
                                                                      o_flg_predef_time_sched_edit => o_flg_predef_time_sched_edit,
                                                                      o_flg_exec_time_edit         => o_flg_exec_time_edit,
                                                                      o_flg_repeat_every_edit      => o_flg_repeat_every_edit,
                                                                      o_flg_repeat_by_edit         => o_flg_repeat_by_edit,
                                                                      o_flg_start_date_edit        => o_flg_start_date_edit,
                                                                      o_flg_end_by_edit            => o_flg_end_by_edit,
                                                                      o_flg_end_after_edit         => o_flg_end_after_edit,
                                                                      o_flg_week_day_edit          => o_flg_week_day_edit,
                                                                      o_flg_week_edit              => o_flg_week_edit,
                                                                      o_flg_month_day_edit         => o_flg_month_day_edit,
                                                                      o_flg_month_edit             => o_flg_month_edit,
                                                                      o_flg_ok_avail               => o_flg_ok_avail,
                                                                      o_error                      => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.get_other_order_recurr_option function';
            RAISE e_user_exception;
        END IF;
    
        g_error := 'OPEN O_EXEC_TIMES';
        OPEN o_exec_times FOR
            SELECT exec_time_parent_option, exec_time_option, exec_time, exec_time_desc
              FROM TABLE(l_exec_times);
    
        -- convert start date and end date to the format supported by the Flash layer
        o_start_date := pk_date_utils.date_send_tsz(i_lang, l_start_date, i_prof);
        o_end_date   := pk_date_utils.date_send_tsz(i_lang, l_end_date, i_prof);
    
        -- process regular interval description
        IF o_regular_interval IS NOT NULL
        THEN
            o_regular_interval_desc := o_regular_interval || ' ' ||
                                       pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                    i_prof,
                                                                                    o_unit_meas_regular_interval);
        END IF;
    
        -- process predefined time schedules field description
        SELECT pk_order_recurrence_core.get_order_recurr_option_desc(i_lang, i_prof, predef_time_sched.column_value) AS predef_time_sched_desc
          BULK COLLECT
          INTO l_predef_time_sched_desc
          FROM TABLE(o_predef_time_sched) predef_time_sched
         ORDER BY upper(predef_time_sched_desc);
    
        o_predef_time_sched_desc := pk_utils.concat_table(l_predef_time_sched_desc, ', ');
    
        -- process recurrence pattern description
        o_recurr_pattern_desc := pk_sysdomain.get_domain('ORDER_RECURR_PLAN.FLG_RECURR_PATTERN',
                                                         o_flg_recurr_pattern,
                                                         i_lang);
    
        -- process recurrence frequency description
        IF o_repeat_every IS NOT NULL
        THEN
            o_repeat_every_desc := o_repeat_every || ' ' ||
                                   pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                i_prof,
                                                                                o_unit_meas_repeat_every);
        END IF;
    
        -- process "repeat by" field description
        o_repeat_by_desc := pk_sysdomain.get_domain('ORDER_RECURR_PLAN.FLG_REPEAT_BY', o_flg_repeat_by, i_lang);
    
        -- process "end by" field description
        o_end_by_desc := pk_sysdomain.get_domain('ORDER_RECURR_PLAN.FLG_END_BY', o_flg_end_by, i_lang);
    
        -- process "end after" field description
        o_end_after_desc := pk_order_recurrence_core.get_order_rec_end_after_desc(i_lang               => i_lang,
                                                                                  i_prof               => i_prof,
                                                                                  i_flg_end_by         => o_flg_end_by,
                                                                                  i_end_date           => l_end_date,
                                                                                  i_duration           => o_duration,
                                                                                  i_unit_meas_duration => o_unit_meas_duration,
                                                                                  i_occurrences        => o_occurrences);
    
        -- process "week day" field description
        SELECT pk_sysdomain.get_domain('ORDER_RECURR_PLAN_PATTERN.FLG_WEEK_DAY', week_day.column_value, i_lang) AS week_day_desc
          BULK COLLECT
          INTO l_week_day_desc
          FROM TABLE(o_flg_week_day) week_day
         ORDER BY week_day.column_value;
    
        o_week_day_desc := pk_utils.concat_table(l_week_day_desc, ', ');
    
        -- process "week" field description
        SELECT pk_sysdomain.get_domain('ORDER_RECURR_PLAN_PATTERN.FLG_WEEK', week.column_value, i_lang) AS week_desc
          BULK COLLECT
          INTO l_week_desc
          FROM TABLE(o_flg_week) week
         ORDER BY week.column_value;
    
        o_week_desc := pk_utils.concat_table(l_week_desc, ', ');
    
        -- process "month" field description
        SELECT to_char(to_date(lpad(month.column_value, 2, '0'), 'MM'),
                       'Month',
                       'NLS_DATE_LANGUAGE = ' || '''' || nls_code || '''') month_desc
          BULK COLLECT
          INTO l_month_desc
          FROM LANGUAGE, TABLE(o_month) MONTH
         WHERE id_language = i_lang
         ORDER BY lpad(month.column_value, 2, '0');
    
        o_month_desc := pk_utils.concat_table(l_month_desc, ', ');
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_OTHER_ORDER_RECURR_OPTION',
                                              o_error);
            pk_types.open_my_cursor(o_exec_times);
            RETURN FALSE;
    END get_other_order_recurr_option;

    FUNCTION get_order_recurr_other_option
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_order_recurr_plan          IN table_number,
        i_flg_context                IN VARCHAR2,
        o_order_recurr_plan          OUT table_number,
        o_regular_interval           OUT table_number,
        o_unit_meas_regular_interval OUT table_number,
        o_regular_interval_desc      OUT VARCHAR2,
        o_daily_executions           OUT table_number,
        o_predef_time_sched          OUT table_table_number,
        o_predef_time_sched_desc     OUT VARCHAR2,
        o_exec_times                 OUT pk_types.cursor_type,
        o_flg_recurr_pattern         OUT table_varchar,
        o_recurr_pattern_desc        OUT VARCHAR2,
        o_repeat_every               OUT table_number,
        o_unit_meas_repeat_every     OUT table_number,
        o_repeat_every_desc          OUT VARCHAR2,
        o_flg_repeat_by              OUT table_varchar,
        o_repeat_by_desc             OUT VARCHAR2,
        o_start_date                 OUT table_varchar,
        o_start_date_desc            OUT VARCHAR2,
        o_flg_end_by                 OUT table_varchar,
        o_end_by_desc                OUT VARCHAR2,
        o_occurrences                OUT table_number,
        o_duration                   OUT table_number,
        o_unit_meas_duration         OUT table_number,
        o_end_date                   OUT table_varchar,
        o_end_after_desc             OUT VARCHAR2,
        o_flg_week_day               OUT table_table_number,
        o_week_day_desc              OUT VARCHAR2,
        o_flg_week                   OUT table_table_number,
        o_week_desc                  OUT VARCHAR2,
        o_month_day                  OUT table_table_number,
        o_month                      OUT table_table_number,
        o_month_desc                 OUT VARCHAR2,
        o_flg_regular_interval_edit  OUT VARCHAR2,
        o_flg_daily_executions_edit  OUT VARCHAR2,
        o_flg_predef_time_sched_edit OUT VARCHAR2,
        o_flg_exec_time_edit         OUT VARCHAR2,
        o_flg_repeat_every_edit      OUT VARCHAR2,
        o_flg_repeat_by_edit         OUT VARCHAR2,
        o_flg_start_date_edit        OUT VARCHAR2,
        o_flg_end_by_edit            OUT VARCHAR2,
        o_flg_end_after_edit         OUT VARCHAR2,
        o_flg_week_day_edit          OUT VARCHAR2,
        o_flg_week_edit              OUT VARCHAR2,
        o_flg_month_day_edit         OUT VARCHAR2,
        o_flg_month_edit             OUT VARCHAR2,
        o_flg_ok_avail               OUT VARCHAR2,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- auxiliary local variables
        l_regular_interval           order_recurr_plan.regular_interval%TYPE;
        l_unit_meas_regular_interval order_recurr_plan.id_unit_meas_regular_interval%TYPE;
        l_daily_executions           order_recurr_plan.daily_executions%TYPE;
        l_predef_time_sched          table_number;
        l_predef_time_sched_desc     table_varchar;
        l_exec_times                 t_tbl_recurr_exec_times;
        l_flg_recurr_pattern         order_recurr_plan.flg_recurr_pattern%TYPE;
        l_repeat_every               order_recurr_plan.repeat_every%TYPE;
        l_unit_meas_repeat_every     unit_measure.id_unit_measure%TYPE;
        l_flg_repeat_by              order_recurr_plan.flg_repeat_by%TYPE;
        l_start_date                 TIMESTAMP WITH LOCAL TIME ZONE;
        l_flg_end_by                 order_recurr_plan.flg_end_by%TYPE;
        l_occurrences                order_recurr_plan.occurrences%TYPE;
        l_duration                   order_recurr_plan.duration%TYPE;
        l_unit_meas_duration         order_recurr_plan.id_unit_meas_duration%TYPE;
        l_end_date                   TIMESTAMP WITH LOCAL TIME ZONE;
        l_flg_week_day               table_number;
        l_week_day_desc              table_varchar;
        l_flg_week                   table_number;
        l_week_desc                  table_varchar;
        l_month_day                  table_number;
        l_month                      table_number;
        l_month_desc                 table_varchar;
        l_flg_regular_interval_edit  VARCHAR2(1 CHAR);
        l_flg_daily_executions_edit  VARCHAR2(1 CHAR);
        l_flg_predef_time_sched_edit VARCHAR2(1 CHAR);
        l_flg_exec_time_edit         VARCHAR2(1 CHAR);
        l_flg_repeat_every_edit      VARCHAR2(1 CHAR);
        l_flg_repeat_by_edit         VARCHAR2(1 CHAR);
        l_flg_start_date_edit        VARCHAR2(1 CHAR);
        l_flg_end_by_edit            VARCHAR2(1 CHAR);
        l_flg_end_after_edit         VARCHAR2(1 CHAR);
        l_flg_week_day_edit          VARCHAR2(1 CHAR);
        l_flg_week_edit              VARCHAR2(1 CHAR);
        l_flg_month_day_edit         VARCHAR2(1 CHAR);
        l_flg_month_edit             VARCHAR2(1 CHAR);
        l_flg_ok_avail               VARCHAR2(1 CHAR);
    
        l_msg_multiple sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M150');
    
    BEGIN
    
        IF i_order_recurr_plan IS NULL
           OR i_order_recurr_plan.count = 0
        THEN
            g_error := 'order recurrence plan ids cannot be empty';
            RAISE e_user_exception;
        END IF;
    
        o_order_recurr_plan          := table_number();
        o_regular_interval           := table_number();
        o_unit_meas_regular_interval := table_number();
        o_daily_executions           := table_number();
        o_predef_time_sched          := table_table_number();
        o_flg_recurr_pattern         := table_varchar();
        o_repeat_every               := table_number();
        o_unit_meas_repeat_every     := table_number();
        o_flg_repeat_by              := table_varchar();
        o_start_date                 := table_varchar();
        o_flg_end_by                 := table_varchar();
        o_occurrences                := table_number();
        o_duration                   := table_number();
        o_unit_meas_duration         := table_number();
        o_end_date                   := table_varchar();
        o_flg_week_day               := table_table_number();
        o_flg_week                   := table_table_number();
        o_month_day                  := table_table_number();
        o_month                      := table_table_number();
    
        DELETE FROM tbl_temp;
    
        FOR i IN 1 .. i_order_recurr_plan.count
        LOOP
            -- call pk_order_recurrence_core.get_other_order_recurr_option function
            IF NOT pk_order_recurrence_core.get_other_order_recurr_option(i_lang                       => i_lang,
                                                                          i_prof                       => i_prof,
                                                                          i_order_recurr_plan          => i_order_recurr_plan(i),
                                                                          i_flg_context                => i_flg_context,
                                                                          o_regular_interval           => l_regular_interval,
                                                                          o_unit_meas_regular_interval => l_unit_meas_regular_interval,
                                                                          o_daily_executions           => l_daily_executions,
                                                                          o_predef_time_sched          => l_predef_time_sched,
                                                                          o_exec_times                 => l_exec_times,
                                                                          o_flg_recurr_pattern         => l_flg_recurr_pattern,
                                                                          o_repeat_every               => l_repeat_every,
                                                                          o_unit_meas_repeat_every     => l_unit_meas_repeat_every,
                                                                          o_flg_repeat_by              => l_flg_repeat_by,
                                                                          o_start_date                 => l_start_date,
                                                                          o_flg_end_by                 => l_flg_end_by,
                                                                          o_occurrences                => l_occurrences,
                                                                          o_duration                   => l_duration,
                                                                          o_unit_meas_duration         => l_unit_meas_duration,
                                                                          o_end_date                   => l_end_date,
                                                                          o_flg_week_day               => l_flg_week_day,
                                                                          o_flg_week                   => l_flg_week,
                                                                          o_month_day                  => l_month_day,
                                                                          o_month                      => l_month,
                                                                          o_flg_regular_interval_edit  => l_flg_regular_interval_edit,
                                                                          o_flg_daily_executions_edit  => l_flg_daily_executions_edit,
                                                                          o_flg_predef_time_sched_edit => l_flg_predef_time_sched_edit,
                                                                          o_flg_exec_time_edit         => l_flg_exec_time_edit,
                                                                          o_flg_repeat_every_edit      => l_flg_repeat_every_edit,
                                                                          o_flg_repeat_by_edit         => l_flg_repeat_by_edit,
                                                                          o_flg_start_date_edit        => l_flg_start_date_edit,
                                                                          o_flg_end_by_edit            => l_flg_end_by_edit,
                                                                          o_flg_end_after_edit         => l_flg_end_after_edit,
                                                                          o_flg_week_day_edit          => l_flg_week_day_edit,
                                                                          o_flg_week_edit              => l_flg_week_edit,
                                                                          o_flg_month_day_edit         => l_flg_month_day_edit,
                                                                          o_flg_month_edit             => l_flg_month_edit,
                                                                          o_flg_ok_avail               => l_flg_ok_avail,
                                                                          o_error                      => o_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.get_other_order_recurr_option function';
                RAISE e_user_exception;
            END IF; -- convert start date and end date to the format supported by the Flash layer
        
            o_order_recurr_plan.extend;
            o_regular_interval.extend;
            o_unit_meas_regular_interval.extend;
            o_daily_executions.extend;
            o_predef_time_sched.extend;
            o_flg_recurr_pattern.extend;
            o_repeat_every.extend;
            o_unit_meas_repeat_every.extend;
            o_flg_repeat_by.extend;
            o_start_date.extend;
            o_flg_end_by.extend;
            o_occurrences.extend;
            o_duration.extend;
            o_unit_meas_duration.extend;
            o_end_date.extend;
            o_flg_week_day.extend;
            o_flg_week.extend;
            o_month_day.extend;
            o_month.extend;
        
            o_order_recurr_plan(i) := i_order_recurr_plan(i);
        
            IF i = 1
            THEN
                -- process regular interval description
                o_regular_interval(i) := l_regular_interval;
                o_unit_meas_regular_interval(i) := l_unit_meas_regular_interval;
            
                IF l_regular_interval IS NOT NULL
                THEN
                    o_regular_interval_desc := l_regular_interval || ' ' ||
                                               pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                            i_prof,
                                                                                            l_unit_meas_regular_interval);
                END IF;
            
                o_daily_executions(i) := l_daily_executions;
            
                IF l_predef_time_sched IS NOT NULL
                   AND l_predef_time_sched.count > 0
                THEN
                    o_predef_time_sched(i) := l_predef_time_sched;
                ELSE
                    o_predef_time_sched(i) := NULL;
                END IF;
            
                -- process predefined time schedules field description
                SELECT pk_order_recurrence_core.get_order_recurr_option_desc(i_lang,
                                                                             i_prof,
                                                                             predef_time_sched.column_value) AS predef_time_sched_desc
                  BULK COLLECT
                  INTO l_predef_time_sched_desc
                  FROM TABLE(l_predef_time_sched) predef_time_sched
                 ORDER BY upper(predef_time_sched_desc);
            
                o_predef_time_sched_desc := pk_utils.concat_table(l_predef_time_sched_desc, ', ');
            
                INSERT INTO tbl_temp
                    (num_1, num_2, num_3, vc_1, vc_2)
                    SELECT id_order_recurr_plan, exec_time_parent_option, exec_time_option, exec_time, exec_time_desc
                      FROM TABLE(l_exec_times);
            
                -- process recurrence pattern description
                o_flg_recurr_pattern(i) := l_flg_recurr_pattern;
                o_recurr_pattern_desc := pk_sysdomain.get_domain('ORDER_RECURR_PLAN.FLG_RECURR_PATTERN',
                                                                 l_flg_recurr_pattern,
                                                                 i_lang);
            
                -- process recurrence frequency description
                o_repeat_every(i) := l_repeat_every;
                o_unit_meas_repeat_every(i) := l_unit_meas_repeat_every;
            
                IF l_repeat_every IS NOT NULL
                THEN
                    o_repeat_every_desc := l_repeat_every || ' ' ||
                                           pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                        i_prof,
                                                                                        l_unit_meas_repeat_every);
                END IF;
            
                -- process "repeat by" field description
                o_flg_repeat_by(i) := l_flg_repeat_by;
                o_repeat_by_desc := pk_sysdomain.get_domain('ORDER_RECURR_PLAN.FLG_REPEAT_BY', l_flg_repeat_by, i_lang);
            
                o_start_date(i) := pk_date_utils.date_send_tsz(i_lang, l_start_date, i_prof);
                o_start_date_desc := pk_date_utils.date_char_tsz(i_lang,
                                                                 l_start_date,
                                                                 i_prof.institution,
                                                                 i_prof.software);
            
                -- process "end by" field description
                o_flg_end_by(i) := l_flg_end_by;
                o_end_by_desc := pk_sysdomain.get_domain('ORDER_RECURR_PLAN.FLG_END_BY', l_flg_end_by, i_lang);
            
                o_occurrences(i) := l_occurrences;
                o_duration(i) := l_duration;
                o_unit_meas_duration(i) := l_unit_meas_duration;
                o_end_date(i) := pk_date_utils.date_send_tsz(i_lang, l_end_date, i_prof);
            
                -- process "end after" field description
                o_end_after_desc := pk_order_recurrence_core.get_order_rec_end_after_desc(i_lang               => i_lang,
                                                                                          i_prof               => i_prof,
                                                                                          i_flg_end_by         => l_flg_end_by,
                                                                                          i_end_date           => l_end_date,
                                                                                          i_duration           => l_duration,
                                                                                          i_unit_meas_duration => l_unit_meas_duration,
                                                                                          i_occurrences        => l_occurrences);
            
                -- process "week" field description
                IF l_flg_week_day IS NOT NULL
                   AND l_flg_week_day.count > 0
                THEN
                    o_flg_week_day(i) := l_flg_week_day;
                ELSE
                    o_flg_week_day(i) := NULL;
                END IF;
            
                SELECT pk_sysdomain.get_domain('ORDER_RECURR_PLAN_PATTERN.FLG_WEEK_DAY', week_day.column_value, i_lang) AS week_day_desc
                  BULK COLLECT
                  INTO l_week_day_desc
                  FROM TABLE(l_flg_week_day) week_day
                 ORDER BY week_day.column_value;
            
                o_week_day_desc := pk_utils.concat_table(l_week_day_desc, ', ');
            
                -- process "week" field description
                IF l_flg_week IS NOT NULL
                   AND l_flg_week.count > 0
                THEN
                    o_flg_week(i) := l_flg_week;
                ELSE
                    o_flg_week(i) := NULL;
                END IF;
            
                SELECT pk_sysdomain.get_domain('ORDER_RECURR_PLAN_PATTERN.FLG_WEEK', week.column_value, i_lang) AS week_desc
                  BULK COLLECT
                  INTO l_week_desc
                  FROM TABLE(l_flg_week) week
                 ORDER BY week.column_value;
            
                o_week_desc := pk_utils.concat_table(l_week_desc, ', ');
            
                -- process "month" field description
                IF l_month IS NOT NULL
                   AND l_month.count > 0
                THEN
                    o_month(i) := l_month;
                ELSE
                    o_month(i) := NULL;
                END IF;
            
                SELECT to_char(to_date(lpad(month.column_value, 2, '0'), 'MM'),
                               'Month',
                               'NLS_DATE_LANGUAGE = ' || '''' || nls_code || '''') month_desc
                  BULK COLLECT
                  INTO l_month_desc
                  FROM LANGUAGE, TABLE(l_month) MONTH
                 WHERE id_language = i_lang
                 ORDER BY lpad(month.column_value, 2, '0');
            
                o_month_desc := pk_utils.concat_table(l_month_desc, ', ');
            
                o_flg_regular_interval_edit  := l_flg_regular_interval_edit;
                o_flg_daily_executions_edit  := l_flg_daily_executions_edit;
                o_flg_predef_time_sched_edit := l_flg_predef_time_sched_edit;
                o_flg_exec_time_edit         := l_flg_exec_time_edit;
                o_flg_repeat_every_edit      := l_flg_repeat_every_edit;
                o_flg_repeat_by_edit         := l_flg_repeat_by_edit;
                o_flg_start_date_edit        := l_flg_start_date_edit;
                o_flg_end_by_edit            := l_flg_end_by_edit;
                o_flg_end_after_edit         := l_flg_end_after_edit;
                o_flg_week_day_edit          := l_flg_week_day_edit;
                o_flg_week_edit              := l_flg_week_edit;
                o_flg_month_day_edit         := l_flg_month_day_edit;
                o_flg_month_edit             := l_flg_month_edit;
                o_flg_ok_avail               := l_flg_ok_avail;
            ELSE
                -- process regular interval description
                o_regular_interval(i) := l_regular_interval;
                o_unit_meas_regular_interval(i) := l_unit_meas_regular_interval;
            
                IF o_regular_interval(1) != l_regular_interval
                   OR o_unit_meas_regular_interval(1) != l_unit_meas_regular_interval
                THEN
                    o_regular_interval_desc := l_msg_multiple;
                END IF;
            
                o_daily_executions(i) := l_daily_executions;
            
                IF l_predef_time_sched IS NOT NULL
                   AND l_predef_time_sched.count > 0
                THEN
                    o_predef_time_sched(i) := l_predef_time_sched;
                ELSE
                    o_predef_time_sched(i) := NULL;
                END IF;
            
                -- process predefined time schedules field description
                SELECT pk_order_recurrence_core.get_order_recurr_option_desc(i_lang,
                                                                             i_prof,
                                                                             predef_time_sched.column_value) AS predef_time_sched_desc
                  BULK COLLECT
                  INTO l_predef_time_sched_desc
                  FROM TABLE(l_predef_time_sched) predef_time_sched
                 ORDER BY upper(predef_time_sched_desc);
            
                o_predef_time_sched_desc := pk_utils.concat_table(l_predef_time_sched_desc, ', ');
            
                INSERT INTO tbl_temp
                    (num_1, num_2, num_3, vc_1, vc_2)
                    SELECT id_order_recurr_plan, exec_time_parent_option, exec_time_option, exec_time, exec_time_desc
                      FROM TABLE(l_exec_times);
            
                -- process recurrence pattern description
                o_flg_recurr_pattern(i) := l_flg_recurr_pattern;
            
                IF o_flg_recurr_pattern(1) != l_flg_recurr_pattern
                THEN
                    o_recurr_pattern_desc := l_msg_multiple;
                END IF;
            
                -- process recurrence frequency description
                o_repeat_every(i) := l_repeat_every;
                o_unit_meas_repeat_every(i) := l_unit_meas_repeat_every;
            
                IF o_repeat_every(1) != l_repeat_every
                   OR o_unit_meas_repeat_every(1) != l_unit_meas_repeat_every
                THEN
                    o_repeat_every_desc := l_msg_multiple;
                END IF;
            
                -- process "repeat by" field descripti
                o_flg_repeat_by(i) := l_flg_repeat_by;
            
                IF o_flg_repeat_by(1) != l_flg_repeat_by
                THEN
                    o_repeat_by_desc := l_msg_multiple;
                END IF;
            
                o_start_date(i) := pk_date_utils.date_send_tsz(i_lang, l_start_date, i_prof);
            
                IF o_start_date(1) != pk_date_utils.date_send_tsz(i_lang, l_start_date, i_prof)
                THEN
                    o_start_date_desc := l_msg_multiple;
                END IF;
            
                -- process "end by" field description
                o_flg_end_by(i) := l_flg_end_by;
            
                IF o_flg_end_by(1) != l_flg_end_by
                THEN
                    o_end_by_desc := l_msg_multiple;
                END IF;
            
                o_occurrences(i) := l_occurrences;
                o_duration(i) := l_duration;
                o_unit_meas_duration(i) := l_unit_meas_duration;
                o_end_date(i) := pk_date_utils.date_send_tsz(i_lang, l_end_date, i_prof);
            
                IF o_occurrences(1) != l_occurrences
                   OR o_duration(1) != l_duration
                   OR o_unit_meas_duration(1) != l_unit_meas_duration
                   OR o_end_date(1) != pk_date_utils.date_send_tsz(i_lang, l_end_date, i_prof)
                THEN
                    o_end_after_desc := l_msg_multiple;
                END IF;
            
                -- process "end after" field description
                o_end_after_desc := pk_order_recurrence_core.get_order_rec_end_after_desc(i_lang               => i_lang,
                                                                                          i_prof               => i_prof,
                                                                                          i_flg_end_by         => l_flg_end_by,
                                                                                          i_end_date           => l_end_date,
                                                                                          i_duration           => l_duration,
                                                                                          i_unit_meas_duration => l_unit_meas_duration,
                                                                                          i_occurrences        => l_occurrences);
            
                IF l_flg_week_day IS NOT NULL
                   AND l_flg_week_day.count > 0
                THEN
                    o_flg_week_day(i) := l_flg_week_day;
                ELSE
                    o_flg_week_day(i) := NULL;
                END IF;
            
                SELECT pk_sysdomain.get_domain('ORDER_RECURR_PLAN_PATTERN.FLG_WEEK_DAY', week_day.column_value, i_lang) AS week_day_desc
                  BULK COLLECT
                  INTO l_week_day_desc
                  FROM TABLE(l_flg_week_day) week_day
                 ORDER BY week_day.column_value;
            
                o_week_day_desc := pk_utils.concat_table(l_week_day_desc, ', ');
            
                -- process "week" field description
                IF l_flg_week IS NOT NULL
                   AND l_flg_week.count > 0
                THEN
                    o_flg_week(i) := l_flg_week;
                ELSE
                    o_flg_week(i) := NULL;
                END IF;
            
                SELECT pk_sysdomain.get_domain('ORDER_RECURR_PLAN_PATTERN.FLG_WEEK', week.column_value, i_lang) AS week_desc
                  BULK COLLECT
                  INTO l_week_desc
                  FROM TABLE(l_flg_week) week
                 ORDER BY week.column_value;
            
                o_week_desc := pk_utils.concat_table(l_week_desc, ', ');
            
                -- process "month" field description
                IF l_month IS NOT NULL
                   AND l_month.count > 0
                THEN
                    o_month(i) := l_month;
                ELSE
                    o_month(i) := NULL;
                END IF;
            
                SELECT to_char(to_date(lpad(month.column_value, 2, '0'), 'MM'),
                               'Month',
                               'NLS_DATE_LANGUAGE = ' || '''' || nls_code || '''') month_desc
                  BULK COLLECT
                  INTO l_month_desc
                  FROM LANGUAGE, TABLE(l_month) MONTH
                 WHERE id_language = i_lang
                 ORDER BY lpad(month.column_value, 2, '0');
            
                o_month_desc := pk_utils.concat_table(l_month_desc, ', ');
            
                o_flg_regular_interval_edit  := l_flg_regular_interval_edit;
                o_flg_daily_executions_edit  := l_flg_daily_executions_edit;
                o_flg_predef_time_sched_edit := l_flg_predef_time_sched_edit;
                o_flg_exec_time_edit         := l_flg_exec_time_edit;
                o_flg_repeat_every_edit      := l_flg_repeat_every_edit;
                o_flg_repeat_by_edit         := l_flg_repeat_by_edit;
                o_flg_start_date_edit        := l_flg_start_date_edit;
                o_flg_end_by_edit            := l_flg_end_by_edit;
                o_flg_end_after_edit         := l_flg_end_after_edit;
                o_flg_week_day_edit          := l_flg_week_day_edit;
                o_flg_week_edit              := l_flg_week_edit;
                o_flg_month_day_edit         := l_flg_month_day_edit;
                o_flg_month_edit             := l_flg_month_edit;
                o_flg_ok_avail               := l_flg_ok_avail;
            END IF;
        END LOOP;
    
        g_error := 'OPEN O_EXEC_TIMES';
        OPEN o_exec_times FOR
            SELECT num_1 id_order_recurr_plan,
                   num_2 exec_time_parent_option,
                   num_3 exec_time_option,
                   vc_1  exec_time,
                   vc_2  exec_time_desc
              FROM tbl_temp;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORDER_RECURR_OTHER_OPTION',
                                              o_error);
            pk_types.open_my_cursor(o_exec_times);
            RETURN FALSE;
    END get_order_recurr_other_option;

    FUNCTION check_other_recurr_option
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_order_recurr_plan          IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_edit_field_name            IN VARCHAR2,
        i_regular_interval           IN order_recurr_plan.regular_interval%TYPE,
        i_unit_meas_regular_interval IN order_recurr_plan.id_unit_meas_regular_interval%TYPE,
        i_daily_executions           IN order_recurr_plan.daily_executions%TYPE,
        i_predef_time_sched          IN table_number,
        i_exec_time_parent_option    IN table_number,
        i_exec_time_option           IN table_number,
        i_exec_time                  IN table_varchar,
        i_exec_time_offset           IN table_number,
        i_unit_meas_exec_time_offset IN table_number,
        i_flg_recurr_pattern         IN order_recurr_plan.flg_recurr_pattern%TYPE,
        i_repeat_every               IN order_recurr_plan.repeat_every%TYPE,
        i_flg_repeat_by              IN order_recurr_plan.flg_repeat_by%TYPE,
        i_start_date                 IN VARCHAR2,
        i_flg_end_by                 IN order_recurr_plan.flg_end_by%TYPE,
        i_occurrences                IN order_recurr_plan.occurrences%TYPE,
        i_duration                   IN order_recurr_plan.duration%TYPE,
        i_unit_meas_duration         IN order_recurr_plan.id_unit_meas_duration%TYPE,
        i_end_date                   IN VARCHAR2,
        i_flg_week_day               IN table_number,
        i_flg_week                   IN table_number,
        i_month_day                  IN table_number,
        i_month                      IN table_number,
        i_flg_context                IN VARCHAR2,
        o_regular_interval           OUT order_recurr_plan.regular_interval%TYPE,
        o_unit_meas_regular_interval OUT order_recurr_plan.id_unit_meas_regular_interval%TYPE,
        o_regular_interval_desc      OUT VARCHAR2,
        o_daily_executions           OUT order_recurr_plan.daily_executions%TYPE,
        o_predef_time_sched          OUT table_number,
        o_predef_time_sched_desc     OUT VARCHAR2,
        o_exec_times                 OUT pk_types.cursor_type,
        o_flg_recurr_pattern         OUT order_recurr_plan.flg_recurr_pattern%TYPE,
        o_recurr_pattern_desc        OUT VARCHAR2,
        o_repeat_every               OUT order_recurr_plan.repeat_every%TYPE,
        o_unit_meas_repeat_every     OUT unit_measure.id_unit_measure%TYPE,
        o_repeat_every_desc          OUT VARCHAR2,
        o_flg_repeat_by              OUT order_recurr_plan.flg_repeat_by%TYPE,
        o_repeat_by_desc             OUT VARCHAR2,
        o_start_date                 OUT VARCHAR2,
        o_flg_end_by                 OUT order_recurr_plan.flg_end_by%TYPE,
        o_end_by_desc                OUT VARCHAR2,
        o_occurrences                OUT order_recurr_plan.occurrences%TYPE,
        o_duration                   OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration         OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_end_date                   OUT VARCHAR2,
        o_end_after_desc             OUT VARCHAR2,
        o_flg_week_day               OUT table_number,
        o_week_day_desc              OUT VARCHAR2,
        o_flg_week                   OUT table_number,
        o_week_desc                  OUT VARCHAR2,
        o_month_day                  OUT table_number,
        o_month                      OUT table_number,
        o_month_desc                 OUT VARCHAR2,
        o_flg_regular_interval_edit  OUT VARCHAR2,
        o_flg_daily_executions_edit  OUT VARCHAR2,
        o_flg_predef_time_sched_edit OUT VARCHAR2,
        o_flg_exec_time_edit         OUT VARCHAR2,
        o_flg_repeat_every_edit      OUT VARCHAR2,
        o_flg_repeat_by_edit         OUT VARCHAR2,
        o_flg_start_date_edit        OUT VARCHAR2,
        o_flg_end_by_edit            OUT VARCHAR2,
        o_flg_end_after_edit         OUT VARCHAR2,
        o_flg_week_day_edit          OUT VARCHAR2,
        o_flg_week_edit              OUT VARCHAR2,
        o_flg_month_day_edit         OUT VARCHAR2,
        o_flg_month_edit             OUT VARCHAR2,
        o_flg_ok_avail               OUT VARCHAR2,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- call check_other_recurr_option function
        IF NOT check_other_recurr_option(i_lang                       => i_lang,
                                         i_prof                       => i_prof,
                                         i_order_recurr_plans         => table_number(i_order_recurr_plan),
                                         i_edit_field_name            => i_edit_field_name,
                                         i_regular_interval           => i_regular_interval,
                                         i_unit_meas_regular_interval => i_unit_meas_regular_interval,
                                         i_daily_executions           => i_daily_executions,
                                         i_predef_time_sched          => i_predef_time_sched,
                                         i_exec_time_parent_option    => i_exec_time_parent_option,
                                         i_exec_time_option           => i_exec_time_option,
                                         i_exec_time                  => i_exec_time,
                                         i_exec_time_offset           => i_exec_time_offset,
                                         i_unit_meas_exec_time_offset => i_unit_meas_exec_time_offset,
                                         i_flg_recurr_pattern         => i_flg_recurr_pattern,
                                         i_repeat_every               => i_repeat_every,
                                         i_flg_repeat_by              => i_flg_repeat_by,
                                         i_start_date                 => i_start_date,
                                         i_flg_end_by                 => i_flg_end_by,
                                         i_occurrences                => i_occurrences,
                                         i_duration                   => i_duration,
                                         i_unit_meas_duration         => i_unit_meas_duration,
                                         i_end_date                   => i_end_date,
                                         i_flg_week_day               => i_flg_week_day,
                                         i_flg_week                   => i_flg_week,
                                         i_month_day                  => i_month_day,
                                         i_month                      => i_month,
                                         i_flg_context                => i_flg_context,
                                         o_regular_interval           => o_regular_interval,
                                         o_unit_meas_regular_interval => o_unit_meas_regular_interval,
                                         o_regular_interval_desc      => o_regular_interval_desc,
                                         o_daily_executions           => o_daily_executions,
                                         o_predef_time_sched          => o_predef_time_sched,
                                         o_predef_time_sched_desc     => o_predef_time_sched_desc,
                                         o_exec_times                 => o_exec_times,
                                         o_flg_recurr_pattern         => o_flg_recurr_pattern,
                                         o_recurr_pattern_desc        => o_recurr_pattern_desc,
                                         o_repeat_every               => o_repeat_every,
                                         o_unit_meas_repeat_every     => o_unit_meas_repeat_every,
                                         o_repeat_every_desc          => o_repeat_every_desc,
                                         o_flg_repeat_by              => o_flg_repeat_by,
                                         o_repeat_by_desc             => o_repeat_by_desc,
                                         o_start_date                 => o_start_date,
                                         o_flg_end_by                 => o_flg_end_by,
                                         o_end_by_desc                => o_end_by_desc,
                                         o_occurrences                => o_occurrences,
                                         o_duration                   => o_duration,
                                         o_unit_meas_duration         => o_unit_meas_duration,
                                         o_end_date                   => o_end_date,
                                         o_end_after_desc             => o_end_after_desc,
                                         o_flg_week_day               => o_flg_week_day,
                                         o_week_day_desc              => o_week_day_desc,
                                         o_flg_week                   => o_flg_week,
                                         o_week_desc                  => o_week_desc,
                                         o_month_day                  => o_month_day,
                                         o_month                      => o_month,
                                         o_month_desc                 => o_month_desc,
                                         o_flg_regular_interval_edit  => o_flg_regular_interval_edit,
                                         o_flg_daily_executions_edit  => o_flg_daily_executions_edit,
                                         o_flg_predef_time_sched_edit => o_flg_predef_time_sched_edit,
                                         o_flg_exec_time_edit         => o_flg_exec_time_edit,
                                         o_flg_repeat_every_edit      => o_flg_repeat_every_edit,
                                         o_flg_repeat_by_edit         => o_flg_repeat_by_edit,
                                         o_flg_start_date_edit        => o_flg_start_date_edit,
                                         o_flg_end_by_edit            => o_flg_end_by_edit,
                                         o_flg_end_after_edit         => o_flg_end_after_edit,
                                         o_flg_week_day_edit          => o_flg_week_day_edit,
                                         o_flg_week_edit              => o_flg_week_edit,
                                         o_flg_month_day_edit         => o_flg_month_day_edit,
                                         o_flg_month_edit             => o_flg_month_edit,
                                         o_flg_ok_avail               => o_flg_ok_avail,
                                         o_error                      => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.check_other_recurr_option function';
            RAISE e_user_exception;
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
                                              'CHECK_OTHER_RECURR_OPTION',
                                              o_error);
            pk_types.open_my_cursor(o_exec_times);
            RETURN FALSE;
    END check_other_recurr_option;

    FUNCTION check_other_recurr_option
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_order_recurr_plans         IN table_number,
        i_edit_field_name            IN VARCHAR2,
        i_regular_interval           IN order_recurr_plan.regular_interval%TYPE,
        i_unit_meas_regular_interval IN order_recurr_plan.id_unit_meas_regular_interval%TYPE,
        i_daily_executions           IN order_recurr_plan.daily_executions%TYPE,
        i_predef_time_sched          IN table_number,
        i_exec_time_parent_option    IN table_number,
        i_exec_time_option           IN table_number,
        i_exec_time                  IN table_varchar,
        i_exec_time_offset           IN table_number,
        i_unit_meas_exec_time_offset IN table_number,
        i_flg_recurr_pattern         IN order_recurr_plan.flg_recurr_pattern%TYPE,
        i_repeat_every               IN order_recurr_plan.repeat_every%TYPE,
        i_flg_repeat_by              IN order_recurr_plan.flg_repeat_by%TYPE,
        i_start_date                 IN VARCHAR2,
        i_flg_end_by                 IN order_recurr_plan.flg_end_by%TYPE,
        i_occurrences                IN order_recurr_plan.occurrences%TYPE,
        i_duration                   IN order_recurr_plan.duration%TYPE,
        i_unit_meas_duration         IN order_recurr_plan.id_unit_meas_duration%TYPE,
        i_end_date                   IN VARCHAR2,
        i_flg_week_day               IN table_number,
        i_flg_week                   IN table_number,
        i_month_day                  IN table_number,
        i_month                      IN table_number,
        i_flg_context                IN VARCHAR2,
        o_regular_interval           OUT order_recurr_plan.regular_interval%TYPE,
        o_unit_meas_regular_interval OUT order_recurr_plan.id_unit_meas_regular_interval%TYPE,
        o_regular_interval_desc      OUT VARCHAR2,
        o_daily_executions           OUT order_recurr_plan.daily_executions%TYPE,
        o_predef_time_sched          OUT table_number,
        o_predef_time_sched_desc     OUT VARCHAR2,
        o_exec_times                 OUT pk_types.cursor_type,
        o_flg_recurr_pattern         OUT order_recurr_plan.flg_recurr_pattern%TYPE,
        o_recurr_pattern_desc        OUT VARCHAR2,
        o_repeat_every               OUT order_recurr_plan.repeat_every%TYPE,
        o_unit_meas_repeat_every     OUT unit_measure.id_unit_measure%TYPE,
        o_repeat_every_desc          OUT VARCHAR2,
        o_flg_repeat_by              OUT order_recurr_plan.flg_repeat_by%TYPE,
        o_repeat_by_desc             OUT VARCHAR2,
        o_start_date                 OUT VARCHAR2,
        o_flg_end_by                 OUT order_recurr_plan.flg_end_by%TYPE,
        o_end_by_desc                OUT VARCHAR2,
        o_occurrences                OUT order_recurr_plan.occurrences%TYPE,
        o_duration                   OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration         OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_end_date                   OUT VARCHAR2,
        o_end_after_desc             OUT VARCHAR2,
        o_flg_week_day               OUT table_number,
        o_week_day_desc              OUT VARCHAR2,
        o_flg_week                   OUT table_number,
        o_week_desc                  OUT VARCHAR2,
        o_month_day                  OUT table_number,
        o_month                      OUT table_number,
        o_month_desc                 OUT VARCHAR2,
        o_flg_regular_interval_edit  OUT VARCHAR2,
        o_flg_daily_executions_edit  OUT VARCHAR2,
        o_flg_predef_time_sched_edit OUT VARCHAR2,
        o_flg_exec_time_edit         OUT VARCHAR2,
        o_flg_repeat_every_edit      OUT VARCHAR2,
        o_flg_repeat_by_edit         OUT VARCHAR2,
        o_flg_start_date_edit        OUT VARCHAR2,
        o_flg_end_by_edit            OUT VARCHAR2,
        o_flg_end_after_edit         OUT VARCHAR2,
        o_flg_week_day_edit          OUT VARCHAR2,
        o_flg_week_edit              OUT VARCHAR2,
        o_flg_month_day_edit         OUT VARCHAR2,
        o_flg_month_edit             OUT VARCHAR2,
        o_flg_ok_avail               OUT VARCHAR2,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- auxiliary local variables
        l_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_predef_time_sched_desc table_varchar;
        l_week_day_desc          table_varchar;
        l_week_desc              table_varchar;
        l_month_desc             table_varchar;
    
        l_exec_times t_tbl_recurr_exec_times;
    
    BEGIN
    
        IF i_order_recurr_plans IS NULL
           OR i_order_recurr_plans.count = 0
        THEN
            g_error := 'order recurrence plan ids cannot be empty';
            RAISE e_user_exception;
        END IF;
    
        DELETE FROM tbl_temp;
    
        g_error := 'FOR i IN 1 .. ' || i_order_recurr_plans.count;
        FOR i IN 1 .. i_order_recurr_plans.count
        LOOP
        
            -- call check_other_recurr_option function
            IF NOT pk_order_recurrence_core.check_other_recurr_option(i_lang                       => i_lang,
                                                                      i_prof                       => i_prof,
                                                                      i_order_recurr_plan          => i_order_recurr_plans(i),
                                                                      i_edit_field_name            => i_edit_field_name,
                                                                      i_regular_interval           => i_regular_interval,
                                                                      i_unit_meas_regular_interval => i_unit_meas_regular_interval,
                                                                      i_daily_executions           => i_daily_executions,
                                                                      i_predef_time_sched          => i_predef_time_sched,
                                                                      i_exec_time_parent_option    => i_exec_time_parent_option,
                                                                      i_exec_time_option           => i_exec_time_option,
                                                                      i_exec_time                  => i_exec_time,
                                                                      i_exec_time_offset           => i_exec_time_offset,
                                                                      i_unit_meas_exec_time_offset => i_unit_meas_exec_time_offset,
                                                                      i_flg_recurr_pattern         => i_flg_recurr_pattern,
                                                                      i_repeat_every               => i_repeat_every,
                                                                      i_flg_repeat_by              => i_flg_repeat_by,
                                                                      i_start_date                 => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                    i_prof,
                                                                                                                                    i_start_date,
                                                                                                                                    NULL),
                                                                      i_flg_end_by                 => i_flg_end_by,
                                                                      i_occurrences                => i_occurrences,
                                                                      i_duration                   => i_duration,
                                                                      i_unit_meas_duration         => i_unit_meas_duration,
                                                                      i_end_date                   => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                    i_prof,
                                                                                                                                    i_end_date,
                                                                                                                                    NULL),
                                                                      i_flg_week_day               => i_flg_week_day,
                                                                      i_flg_week                   => i_flg_week,
                                                                      i_month_day                  => i_month_day,
                                                                      i_month                      => i_month,
                                                                      i_flg_context                => i_flg_context,
                                                                      o_regular_interval           => o_regular_interval,
                                                                      o_unit_meas_regular_interval => o_unit_meas_regular_interval,
                                                                      o_daily_executions           => o_daily_executions,
                                                                      o_predef_time_sched          => o_predef_time_sched,
                                                                      o_exec_times                 => l_exec_times,
                                                                      o_flg_recurr_pattern         => o_flg_recurr_pattern,
                                                                      o_repeat_every               => o_repeat_every,
                                                                      o_unit_meas_repeat_every     => o_unit_meas_repeat_every,
                                                                      o_flg_repeat_by              => o_flg_repeat_by,
                                                                      o_start_date                 => l_start_date,
                                                                      o_flg_end_by                 => o_flg_end_by,
                                                                      o_occurrences                => o_occurrences,
                                                                      o_duration                   => o_duration,
                                                                      o_unit_meas_duration         => o_unit_meas_duration,
                                                                      o_end_date                   => l_end_date,
                                                                      o_flg_week_day               => o_flg_week_day,
                                                                      o_flg_week                   => o_flg_week,
                                                                      o_month_day                  => o_month_day,
                                                                      o_month                      => o_month,
                                                                      o_flg_regular_interval_edit  => o_flg_regular_interval_edit,
                                                                      o_flg_daily_executions_edit  => o_flg_daily_executions_edit,
                                                                      o_flg_predef_time_sched_edit => o_flg_predef_time_sched_edit,
                                                                      o_flg_exec_time_edit         => o_flg_exec_time_edit,
                                                                      o_flg_repeat_every_edit      => o_flg_repeat_every_edit,
                                                                      o_flg_repeat_by_edit         => o_flg_repeat_by_edit,
                                                                      o_flg_start_date_edit        => o_flg_start_date_edit,
                                                                      o_flg_end_by_edit            => o_flg_end_by_edit,
                                                                      o_flg_end_after_edit         => o_flg_end_after_edit,
                                                                      o_flg_week_day_edit          => o_flg_week_day_edit,
                                                                      o_flg_week_edit              => o_flg_week_edit,
                                                                      o_flg_month_day_edit         => o_flg_month_day_edit,
                                                                      o_flg_month_edit             => o_flg_month_edit,
                                                                      o_flg_ok_avail               => o_flg_ok_avail,
                                                                      o_error                      => o_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.check_other_recurr_option function';
                RAISE e_user_exception;
            END IF;
        END LOOP;
    
        g_error := 'OPEN O_EXEC_TIMES';
        OPEN o_exec_times FOR
            SELECT exec_time_parent_option, exec_time_option, exec_time, exec_time_desc
              FROM TABLE(l_exec_times);
    
        -- convert start date and end date to the format supported by the Flash layer
        o_start_date := pk_date_utils.date_send_tsz(i_lang, l_start_date, i_prof);
        o_end_date   := pk_date_utils.date_send_tsz(i_lang, l_end_date, i_prof);
    
        -- process regular interval description
        IF o_regular_interval IS NOT NULL
        THEN
            o_regular_interval_desc := o_regular_interval || ' ' ||
                                       pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                    i_prof,
                                                                                    o_unit_meas_regular_interval);
        END IF;
    
        -- process predefined time schedules field description
        SELECT pk_order_recurrence_core.get_order_recurr_option_desc(i_lang, i_prof, predef_time_sched.column_value) AS predef_time_sched_desc
          BULK COLLECT
          INTO l_predef_time_sched_desc
          FROM TABLE(o_predef_time_sched) predef_time_sched
         ORDER BY upper(predef_time_sched_desc);
    
        o_predef_time_sched_desc := pk_utils.concat_table(l_predef_time_sched_desc, ', ');
    
        -- process recurrence pattern description
        o_recurr_pattern_desc := pk_sysdomain.get_domain('ORDER_RECURR_PLAN.FLG_RECURR_PATTERN',
                                                         o_flg_recurr_pattern,
                                                         i_lang);
    
        -- process recurrence frequency description
        IF o_repeat_every IS NOT NULL
        THEN
            o_repeat_every_desc := o_repeat_every || ' ' ||
                                   pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                i_prof,
                                                                                o_unit_meas_repeat_every);
        END IF;
    
        -- process "repeat by" field description
        o_repeat_by_desc := pk_sysdomain.get_domain('ORDER_RECURR_PLAN.FLG_REPEAT_BY', o_flg_repeat_by, i_lang);
    
        -- process "end by" field description
        o_end_by_desc := pk_sysdomain.get_domain('ORDER_RECURR_PLAN.FLG_END_BY', o_flg_end_by, i_lang);
    
        -- process "end after" field description
        o_end_after_desc := pk_order_recurrence_core.get_order_rec_end_after_desc(i_lang               => i_lang,
                                                                                  i_prof               => i_prof,
                                                                                  i_flg_end_by         => o_flg_end_by,
                                                                                  i_end_date           => l_end_date,
                                                                                  i_duration           => o_duration,
                                                                                  i_unit_meas_duration => o_unit_meas_duration,
                                                                                  i_occurrences        => o_occurrences);
    
        -- process "week day" field description
        SELECT pk_sysdomain.get_domain('ORDER_RECURR_PLAN_PATTERN.FLG_WEEK_DAY', week_day.column_value, i_lang) AS week_day_desc
          BULK COLLECT
          INTO l_week_day_desc
          FROM TABLE(o_flg_week_day) week_day
         ORDER BY week_day.column_value;
    
        o_week_day_desc := pk_utils.concat_table(l_week_day_desc, ', ');
    
        -- process "week" field description
        SELECT pk_sysdomain.get_domain('ORDER_RECURR_PLAN_PATTERN.FLG_WEEK', week.column_value, i_lang) AS week_desc
          BULK COLLECT
          INTO l_week_desc
          FROM TABLE(o_flg_week) week
         ORDER BY week.column_value;
    
        o_week_desc := pk_utils.concat_table(l_week_desc, ', ');
    
        -- process "month" field description
        SELECT to_char(to_date(lpad(month.column_value, 2, '0'), 'MM'),
                       'Month',
                       'NLS_DATE_LANGUAGE = ' || '''' || nls_code || '''') month_desc
          BULK COLLECT
          INTO l_month_desc
          FROM LANGUAGE, TABLE(o_month) MONTH
         WHERE id_language = i_lang
         ORDER BY lpad(month.column_value, 2, '0');
    
        o_month_desc := pk_utils.concat_table(l_month_desc, ', ');
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_OTHER_RECURR_OPTION',
                                              o_error);
            pk_types.open_my_cursor(o_exec_times);
            RETURN FALSE;
    END check_other_recurr_option;

    FUNCTION check_order_recurr_option
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_order_recurr_plan          IN table_number,
        i_edit_field_name            IN table_varchar,
        i_regular_interval           IN table_number,
        i_unit_meas_regular_interval IN table_number,
        i_daily_executions           IN table_number,
        i_predef_time_sched          IN table_table_number,
        i_exec_time_parent_option    IN table_table_number,
        i_exec_time_option           IN table_table_number,
        i_exec_time                  IN table_table_varchar,
        i_flg_recurr_pattern         IN table_varchar,
        i_repeat_every               IN table_number,
        i_flg_repeat_by              IN table_varchar,
        i_start_date                 IN table_varchar,
        i_flg_end_by                 IN table_varchar,
        i_occurrences                IN table_number,
        i_duration                   IN table_number,
        i_unit_meas_duration         IN table_number,
        i_end_date                   IN table_varchar,
        i_flg_week_day               IN table_table_number,
        i_flg_week                   IN table_table_number,
        i_month_day                  IN table_table_number,
        i_month                      IN table_table_number,
        i_flg_context                IN VARCHAR2,
        o_order_recurr_plan          OUT table_number,
        o_regular_interval           OUT table_number,
        o_unit_meas_regular_interval OUT table_number,
        o_regular_interval_desc      OUT VARCHAR2,
        o_daily_executions           OUT table_number,
        o_predef_time_sched          OUT table_table_number,
        o_predef_time_sched_desc     OUT VARCHAR2,
        o_exec_times                 OUT pk_types.cursor_type,
        o_flg_recurr_pattern         OUT table_varchar,
        o_recurr_pattern_desc        OUT VARCHAR2,
        o_repeat_every               OUT table_number,
        o_unit_meas_repeat_every     OUT table_number,
        o_repeat_every_desc          OUT VARCHAR2,
        o_flg_repeat_by              OUT table_varchar,
        o_repeat_by_desc             OUT VARCHAR2,
        o_start_date                 OUT table_varchar,
        o_start_date_desc            OUT VARCHAR2,
        o_flg_end_by                 OUT table_varchar,
        o_end_by_desc                OUT VARCHAR2,
        o_occurrences                OUT table_number,
        o_duration                   OUT table_number,
        o_unit_meas_duration         OUT table_number,
        o_end_date                   OUT table_varchar,
        o_end_after_desc             OUT VARCHAR2,
        o_flg_week_day               OUT table_table_number,
        o_week_day_desc              OUT VARCHAR2,
        o_flg_week                   OUT table_table_number,
        o_week_desc                  OUT VARCHAR2,
        o_month_day                  OUT table_table_number,
        o_month                      OUT table_table_number,
        o_month_desc                 OUT VARCHAR2,
        o_flg_regular_interval_edit  OUT VARCHAR2,
        o_flg_daily_executions_edit  OUT VARCHAR2,
        o_flg_predef_time_sched_edit OUT VARCHAR2,
        o_flg_exec_time_edit         OUT VARCHAR2,
        o_flg_repeat_every_edit      OUT VARCHAR2,
        o_flg_repeat_by_edit         OUT VARCHAR2,
        o_flg_start_date_edit        OUT VARCHAR2,
        o_flg_end_by_edit            OUT VARCHAR2,
        o_flg_end_after_edit         OUT VARCHAR2,
        o_flg_week_day_edit          OUT VARCHAR2,
        o_flg_week_edit              OUT VARCHAR2,
        o_flg_month_day_edit         OUT VARCHAR2,
        o_flg_month_edit             OUT VARCHAR2,
        o_flg_ok_avail               OUT VARCHAR2,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- auxiliary local variables
        l_regular_interval           order_recurr_plan.regular_interval%TYPE;
        l_unit_meas_regular_interval order_recurr_plan.id_unit_meas_regular_interval%TYPE;
        l_daily_executions           order_recurr_plan.daily_executions%TYPE;
        l_predef_time_sched          table_number;
        l_predef_time_sched_desc     table_varchar;
        l_exec_times                 t_tbl_recurr_exec_times;
        l_exec_time_offset           table_number;
        l_unit_meas_exec_time_offset table_number;
        l_flg_recurr_pattern         order_recurr_plan.flg_recurr_pattern%TYPE;
        l_repeat_every               order_recurr_plan.repeat_every%TYPE;
        l_unit_meas_repeat_every     unit_measure.id_unit_measure%TYPE;
        l_flg_repeat_by              order_recurr_plan.flg_repeat_by%TYPE;
        l_start_date                 TIMESTAMP WITH LOCAL TIME ZONE;
        l_flg_end_by                 order_recurr_plan.flg_end_by%TYPE;
        l_occurrences                order_recurr_plan.occurrences%TYPE;
        l_duration                   order_recurr_plan.duration%TYPE;
        l_unit_meas_duration         order_recurr_plan.id_unit_meas_duration%TYPE;
        l_end_date                   TIMESTAMP WITH LOCAL TIME ZONE;
        l_flg_week_day               table_number;
        l_week_day_desc              table_varchar;
        l_flg_week                   table_number;
        l_week_desc                  table_varchar;
        l_month_day                  table_number;
        l_month                      table_number;
        l_month_desc                 table_varchar;
        l_flg_regular_interval_edit  VARCHAR2(1 CHAR);
        l_flg_daily_executions_edit  VARCHAR2(1 CHAR);
        l_flg_predef_time_sched_edit VARCHAR2(1 CHAR);
        l_flg_exec_time_edit         VARCHAR2(1 CHAR);
        l_flg_repeat_every_edit      VARCHAR2(1 CHAR);
        l_flg_repeat_by_edit         VARCHAR2(1 CHAR);
        l_flg_start_date_edit        VARCHAR2(1 CHAR);
        l_flg_end_by_edit            VARCHAR2(1 CHAR);
        l_flg_end_after_edit         VARCHAR2(1 CHAR);
        l_flg_week_day_edit          VARCHAR2(1 CHAR);
        l_flg_week_edit              VARCHAR2(1 CHAR);
        l_flg_month_day_edit         VARCHAR2(1 CHAR);
        l_flg_month_edit             VARCHAR2(1 CHAR);
        l_flg_ok_avail               VARCHAR2(1 CHAR);
    
        l_msg_multiple sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M150');
    
    BEGIN
    
        IF i_order_recurr_plan IS NULL
           OR i_order_recurr_plan.count = 0
        THEN
            g_error := 'order recurrence plan ids cannot be empty';
            RAISE e_user_exception;
        END IF;
    
        o_order_recurr_plan          := table_number();
        o_regular_interval           := table_number();
        o_unit_meas_regular_interval := table_number();
        o_daily_executions           := table_number();
        o_predef_time_sched          := table_table_number();
        o_flg_recurr_pattern         := table_varchar();
        o_repeat_every               := table_number();
        o_unit_meas_repeat_every     := table_number();
        o_flg_repeat_by              := table_varchar();
        o_start_date                 := table_varchar();
        o_flg_end_by                 := table_varchar();
        o_occurrences                := table_number();
        o_duration                   := table_number();
        o_unit_meas_duration         := table_number();
        o_end_date                   := table_varchar();
        o_flg_week_day               := table_table_number();
        o_flg_week                   := table_table_number();
        o_month_day                  := table_table_number();
        o_month                      := table_table_number();
    
        DELETE FROM tbl_temp;
    
        g_error := 'FOR i IN 1 .. ' || i_order_recurr_plan.count;
        FOR i IN 1 .. i_order_recurr_plan.count
        LOOP
        
            l_exec_time_offset           := table_number();
            l_unit_meas_exec_time_offset := table_number();
            IF i_exec_time(i).count > 0
            THEN
                FOR j IN i_exec_time(i).first .. i_exec_time(i).last
                LOOP
                    l_exec_time_offset.extend;
                    l_exec_time_offset(j) := NULL;
                
                    l_unit_meas_exec_time_offset.extend;
                    l_unit_meas_exec_time_offset(j) := NULL;
                END LOOP;
            END IF;
        
            -- call check_other_recurr_option function
            IF NOT pk_order_recurrence_core.check_other_recurr_option(i_lang                       => i_lang,
                                                                      i_prof                       => i_prof,
                                                                      i_order_recurr_plan          => i_order_recurr_plan(i),
                                                                      i_edit_field_name            => i_edit_field_name(i),
                                                                      i_regular_interval           => i_regular_interval(i),
                                                                      i_unit_meas_regular_interval => i_unit_meas_regular_interval(i),
                                                                      i_daily_executions           => i_daily_executions(i),
                                                                      i_predef_time_sched          => i_predef_time_sched(i),
                                                                      i_exec_time_parent_option    => i_exec_time_parent_option(i),
                                                                      i_exec_time_option           => i_exec_time_option(i),
                                                                      i_exec_time                  => i_exec_time(i),
                                                                      i_exec_time_offset           => l_exec_time_offset,
                                                                      i_unit_meas_exec_time_offset => l_unit_meas_exec_time_offset,
                                                                      i_flg_recurr_pattern         => i_flg_recurr_pattern(i),
                                                                      i_repeat_every               => i_repeat_every(i),
                                                                      i_flg_repeat_by              => i_flg_repeat_by(i),
                                                                      i_start_date                 => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                    i_prof,
                                                                                                                                    i_start_date(i),
                                                                                                                                    NULL),
                                                                      i_flg_end_by                 => i_flg_end_by(i),
                                                                      i_occurrences                => i_occurrences(i),
                                                                      i_duration                   => i_duration(i),
                                                                      i_unit_meas_duration         => i_unit_meas_duration(i),
                                                                      i_end_date                   => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                    i_prof,
                                                                                                                                    i_end_date(i),
                                                                                                                                    NULL),
                                                                      i_flg_week_day               => i_flg_week_day(i),
                                                                      i_flg_week                   => i_flg_week(i),
                                                                      i_month_day                  => i_month_day(i),
                                                                      i_month                      => i_month(i),
                                                                      i_flg_context                => i_flg_context,
                                                                      o_regular_interval           => l_regular_interval,
                                                                      o_unit_meas_regular_interval => l_unit_meas_regular_interval,
                                                                      o_daily_executions           => l_daily_executions,
                                                                      o_predef_time_sched          => l_predef_time_sched,
                                                                      o_exec_times                 => l_exec_times,
                                                                      o_flg_recurr_pattern         => l_flg_recurr_pattern,
                                                                      o_repeat_every               => l_repeat_every,
                                                                      o_unit_meas_repeat_every     => l_unit_meas_repeat_every,
                                                                      o_flg_repeat_by              => l_flg_repeat_by,
                                                                      o_start_date                 => l_start_date,
                                                                      o_flg_end_by                 => l_flg_end_by,
                                                                      o_occurrences                => l_occurrences,
                                                                      o_duration                   => l_duration,
                                                                      o_unit_meas_duration         => l_unit_meas_duration,
                                                                      o_end_date                   => l_end_date,
                                                                      o_flg_week_day               => l_flg_week_day,
                                                                      o_flg_week                   => l_flg_week,
                                                                      o_month_day                  => l_month_day,
                                                                      o_month                      => l_month,
                                                                      o_flg_regular_interval_edit  => l_flg_regular_interval_edit,
                                                                      o_flg_daily_executions_edit  => l_flg_daily_executions_edit,
                                                                      o_flg_predef_time_sched_edit => l_flg_predef_time_sched_edit,
                                                                      o_flg_exec_time_edit         => l_flg_exec_time_edit,
                                                                      o_flg_repeat_every_edit      => l_flg_repeat_every_edit,
                                                                      o_flg_repeat_by_edit         => l_flg_repeat_by_edit,
                                                                      o_flg_start_date_edit        => l_flg_start_date_edit,
                                                                      o_flg_end_by_edit            => l_flg_end_by_edit,
                                                                      o_flg_end_after_edit         => l_flg_end_after_edit,
                                                                      o_flg_week_day_edit          => l_flg_week_day_edit,
                                                                      o_flg_week_edit              => l_flg_week_edit,
                                                                      o_flg_month_day_edit         => l_flg_month_day_edit,
                                                                      o_flg_month_edit             => l_flg_month_edit,
                                                                      o_flg_ok_avail               => l_flg_ok_avail,
                                                                      o_error                      => o_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.check_other_recurr_option function';
                RAISE e_user_exception;
            END IF;
        
            o_order_recurr_plan.extend;
            o_regular_interval.extend;
            o_unit_meas_regular_interval.extend;
            o_daily_executions.extend;
            o_predef_time_sched.extend;
            o_flg_recurr_pattern.extend;
            o_repeat_every.extend;
            o_unit_meas_repeat_every.extend;
            o_flg_repeat_by.extend;
            o_start_date.extend;
            o_flg_end_by.extend;
            o_occurrences.extend;
            o_duration.extend;
            o_unit_meas_duration.extend;
            o_end_date.extend;
            o_flg_week_day.extend;
            o_flg_week.extend;
            o_month_day.extend;
            o_month.extend;
        
            o_order_recurr_plan(i) := i_order_recurr_plan(i);
        
            IF i = 1
            THEN
                -- process regular interval description
                o_regular_interval(i) := l_regular_interval;
                o_unit_meas_regular_interval(i) := l_unit_meas_regular_interval;
            
                IF l_regular_interval IS NOT NULL
                THEN
                    o_regular_interval_desc := l_regular_interval || ' ' ||
                                               pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                            i_prof,
                                                                                            l_unit_meas_regular_interval);
                END IF;
            
                o_daily_executions(i) := l_daily_executions;
            
                IF l_predef_time_sched IS NOT NULL
                   AND l_predef_time_sched.count > 0
                THEN
                    o_predef_time_sched(i) := l_predef_time_sched;
                ELSE
                    o_predef_time_sched(i) := NULL;
                END IF;
            
                -- process predefined time schedules field description
                SELECT pk_order_recurrence_core.get_order_recurr_option_desc(i_lang,
                                                                             i_prof,
                                                                             predef_time_sched.column_value) AS predef_time_sched_desc
                  BULK COLLECT
                  INTO l_predef_time_sched_desc
                  FROM TABLE(l_predef_time_sched) predef_time_sched
                 ORDER BY upper(predef_time_sched_desc);
            
                o_predef_time_sched_desc := pk_utils.concat_table(l_predef_time_sched_desc, ', ');
            
                INSERT INTO tbl_temp
                    (num_1, num_2, num_3, vc_1, vc_2)
                    SELECT id_order_recurr_plan, exec_time_parent_option, exec_time_option, exec_time, exec_time_desc
                      FROM TABLE(l_exec_times);
            
                -- process recurrence pattern description
                o_flg_recurr_pattern(i) := l_flg_recurr_pattern;
                o_recurr_pattern_desc := pk_sysdomain.get_domain('ORDER_RECURR_PLAN.FLG_RECURR_PATTERN',
                                                                 l_flg_recurr_pattern,
                                                                 i_lang);
            
                -- process recurrence frequency description
                o_repeat_every(i) := l_repeat_every;
                o_unit_meas_repeat_every(i) := l_unit_meas_repeat_every;
            
                IF l_repeat_every IS NOT NULL
                THEN
                    o_repeat_every_desc := l_repeat_every || ' ' ||
                                           pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                        i_prof,
                                                                                        l_unit_meas_repeat_every);
                END IF;
            
                -- process "repeat by" field description
                o_flg_repeat_by(i) := l_flg_repeat_by;
                o_repeat_by_desc := pk_sysdomain.get_domain('ORDER_RECURR_PLAN.FLG_REPEAT_BY', l_flg_repeat_by, i_lang);
            
                o_start_date(i) := pk_date_utils.date_send_tsz(i_lang, l_start_date, i_prof);
                o_start_date_desc := pk_date_utils.date_char_tsz(i_lang,
                                                                 l_start_date,
                                                                 i_prof.institution,
                                                                 i_prof.software);
            
                -- process "end by" field description
                o_flg_end_by(i) := l_flg_end_by;
                o_end_by_desc := pk_sysdomain.get_domain('ORDER_RECURR_PLAN.FLG_END_BY', l_flg_end_by, i_lang);
            
                o_occurrences(i) := l_occurrences;
                o_duration(i) := l_duration;
                o_unit_meas_duration(i) := l_unit_meas_duration;
                o_end_date(i) := pk_date_utils.date_send_tsz(i_lang, l_end_date, i_prof);
            
                -- process "end after" field description
                o_end_after_desc := pk_order_recurrence_core.get_order_rec_end_after_desc(i_lang               => i_lang,
                                                                                          i_prof               => i_prof,
                                                                                          i_flg_end_by         => l_flg_end_by,
                                                                                          i_end_date           => l_end_date,
                                                                                          i_duration           => l_duration,
                                                                                          i_unit_meas_duration => l_unit_meas_duration,
                                                                                          i_occurrences        => l_occurrences);
            
                -- process "week day" field description
                IF l_flg_week_day IS NOT NULL
                   AND l_flg_week_day.count > 0
                THEN
                    o_flg_week_day(i) := l_flg_week_day;
                ELSE
                    o_flg_week_day(i) := NULL;
                END IF;
            
                SELECT pk_sysdomain.get_domain('ORDER_RECURR_PLAN_PATTERN.FLG_WEEK_DAY', week_day.column_value, i_lang) AS week_day_desc
                  BULK COLLECT
                  INTO l_week_day_desc
                  FROM TABLE(l_flg_week_day) week_day
                 ORDER BY week_day.column_value;
            
                o_week_day_desc := pk_utils.concat_table(l_week_day_desc, ', ');
            
                -- process "week" field description
                IF l_flg_week IS NOT NULL
                   AND l_flg_week.count > 0
                THEN
                    o_flg_week(i) := l_flg_week;
                ELSE
                    o_flg_week(i) := NULL;
                END IF;
            
                SELECT pk_sysdomain.get_domain('ORDER_RECURR_PLAN_PATTERN.FLG_WEEK', week.column_value, i_lang) AS week_desc
                  BULK COLLECT
                  INTO l_week_desc
                  FROM TABLE(l_flg_week) week
                 ORDER BY week.column_value;
            
                o_week_desc := pk_utils.concat_table(l_week_desc, ', ');
            
                -- process "month" field description
                IF l_month IS NOT NULL
                   AND l_month.count > 0
                THEN
                    o_month(i) := l_month;
                ELSE
                    o_month(i) := NULL;
                END IF;
            
                SELECT to_char(to_date(lpad(month.column_value, 2, '0'), 'MM'),
                               'Month',
                               'NLS_DATE_LANGUAGE = ' || '''' || nls_code || '''') month_desc
                  BULK COLLECT
                  INTO l_month_desc
                  FROM LANGUAGE, TABLE(l_month) MONTH
                 WHERE id_language = i_lang
                 ORDER BY lpad(month.column_value, 2, '0');
            
                o_month_desc := pk_utils.concat_table(l_month_desc, ', ');
            
                o_flg_regular_interval_edit  := l_flg_regular_interval_edit;
                o_flg_daily_executions_edit  := l_flg_daily_executions_edit;
                o_flg_predef_time_sched_edit := l_flg_predef_time_sched_edit;
                o_flg_exec_time_edit         := l_flg_exec_time_edit;
                o_flg_repeat_every_edit      := l_flg_repeat_every_edit;
                o_flg_repeat_by_edit         := l_flg_repeat_by_edit;
                o_flg_start_date_edit        := l_flg_start_date_edit;
                o_flg_end_by_edit            := l_flg_end_by_edit;
                o_flg_end_after_edit         := l_flg_end_after_edit;
                o_flg_week_day_edit          := l_flg_week_day_edit;
                o_flg_week_edit              := l_flg_week_edit;
                o_flg_month_day_edit         := l_flg_month_day_edit;
                o_flg_month_edit             := l_flg_month_edit;
                o_flg_ok_avail               := l_flg_ok_avail;
            ELSE
                -- process regular interval description
                o_regular_interval(i) := l_regular_interval;
                o_unit_meas_regular_interval(i) := l_unit_meas_regular_interval;
            
                IF o_regular_interval(1) != l_regular_interval
                   OR o_unit_meas_regular_interval(1) != l_unit_meas_regular_interval
                THEN
                    o_regular_interval_desc := l_msg_multiple;
                END IF;
            
                o_daily_executions(i) := l_daily_executions;
            
                IF l_predef_time_sched IS NOT NULL
                   AND l_predef_time_sched.count > 0
                THEN
                    o_predef_time_sched(i) := l_predef_time_sched;
                ELSE
                    o_predef_time_sched(i) := NULL;
                END IF;
            
                -- process predefined time schedules field description
                SELECT pk_order_recurrence_core.get_order_recurr_option_desc(i_lang,
                                                                             i_prof,
                                                                             predef_time_sched.column_value) AS predef_time_sched_desc
                  BULK COLLECT
                  INTO l_predef_time_sched_desc
                  FROM TABLE(l_predef_time_sched) predef_time_sched
                 ORDER BY upper(predef_time_sched_desc);
            
                o_predef_time_sched_desc := pk_utils.concat_table(l_predef_time_sched_desc, ', ');
            
                INSERT INTO tbl_temp
                    (num_1, num_2, num_3, vc_1, vc_2)
                    SELECT id_order_recurr_plan, exec_time_parent_option, exec_time_option, exec_time, exec_time_desc
                      FROM TABLE(l_exec_times);
            
                -- process recurrence pattern description
                o_flg_recurr_pattern(i) := l_flg_recurr_pattern;
            
                IF o_flg_recurr_pattern(1) != l_flg_recurr_pattern
                THEN
                    o_recurr_pattern_desc := l_msg_multiple;
                END IF;
            
                -- process recurrence frequency description
                o_repeat_every(i) := l_repeat_every;
                o_unit_meas_repeat_every(i) := l_unit_meas_repeat_every;
            
                IF o_repeat_every(1) != l_repeat_every
                   OR o_unit_meas_repeat_every(1) != l_unit_meas_repeat_every
                THEN
                    o_repeat_every_desc := l_msg_multiple;
                END IF;
            
                -- process "repeat by" field descripti
                o_flg_repeat_by(i) := l_flg_repeat_by;
            
                IF o_flg_repeat_by(1) != l_flg_repeat_by
                THEN
                    o_repeat_by_desc := l_msg_multiple;
                END IF;
            
                o_start_date(i) := pk_date_utils.date_send_tsz(i_lang, l_start_date, i_prof);
            
                IF o_start_date(1) != pk_date_utils.date_send_tsz(i_lang, l_start_date, i_prof)
                THEN
                    o_start_date_desc := l_msg_multiple;
                END IF;
            
                -- process "end by" field description
                o_flg_end_by(i) := l_flg_end_by;
            
                IF o_flg_end_by(1) != l_flg_end_by
                THEN
                    o_end_by_desc := l_msg_multiple;
                END IF;
            
                o_occurrences(i) := l_occurrences;
                o_duration(i) := l_duration;
                o_unit_meas_duration(i) := l_unit_meas_duration;
                o_end_date(i) := pk_date_utils.date_send_tsz(i_lang, l_end_date, i_prof);
            
                IF o_occurrences(1) != l_occurrences
                   OR o_duration(1) != l_duration
                   OR o_unit_meas_duration(1) != l_unit_meas_duration
                   OR o_end_date(1) != pk_date_utils.date_send_tsz(i_lang, l_end_date, i_prof)
                THEN
                    o_end_after_desc := l_msg_multiple;
                END IF;
            
                -- process "end after" field description
                o_end_after_desc := pk_order_recurrence_core.get_order_rec_end_after_desc(i_lang               => i_lang,
                                                                                          i_prof               => i_prof,
                                                                                          i_flg_end_by         => l_flg_end_by,
                                                                                          i_end_date           => l_end_date,
                                                                                          i_duration           => l_duration,
                                                                                          i_unit_meas_duration => l_unit_meas_duration,
                                                                                          i_occurrences        => l_occurrences);
            
                -- process "week day" field description
                IF l_flg_week_day IS NOT NULL
                   AND l_flg_week_day.count > 0
                THEN
                    o_flg_week_day(i) := l_flg_week_day;
                ELSE
                    o_flg_week_day(i) := NULL;
                END IF;
            
                SELECT pk_sysdomain.get_domain('ORDER_RECURR_PLAN_PATTERN.FLG_WEEK_DAY', week_day.column_value, i_lang) AS week_day_desc
                  BULK COLLECT
                  INTO l_week_day_desc
                  FROM TABLE(l_flg_week_day) week_day
                 ORDER BY week_day.column_value;
            
                o_week_day_desc := pk_utils.concat_table(l_week_day_desc, ', ');
            
                -- process "week" field description
                IF l_flg_week IS NOT NULL
                   AND l_flg_week.count > 0
                THEN
                    o_flg_week(i) := l_flg_week;
                ELSE
                    o_flg_week(i) := NULL;
                END IF;
            
                SELECT pk_sysdomain.get_domain('ORDER_RECURR_PLAN_PATTERN.FLG_WEEK', week.column_value, i_lang) AS week_desc
                  BULK COLLECT
                  INTO l_week_desc
                  FROM TABLE(l_flg_week) week
                 ORDER BY week.column_value;
            
                o_week_desc := pk_utils.concat_table(l_week_desc, ', ');
            
                -- process "month" field description
                IF l_month IS NOT NULL
                   AND l_month.count > 0
                THEN
                    o_month(i) := l_month;
                ELSE
                    o_month(i) := NULL;
                END IF;
            
                SELECT to_char(to_date(lpad(month.column_value, 2, '0'), 'MM'),
                               'Month',
                               'NLS_DATE_LANGUAGE = ' || '''' || nls_code || '''') month_desc
                  BULK COLLECT
                  INTO l_month_desc
                  FROM LANGUAGE, TABLE(l_month) MONTH
                 WHERE id_language = i_lang
                 ORDER BY lpad(month.column_value, 2, '0');
            
                o_month_desc := pk_utils.concat_table(l_month_desc, ', ');
            
                o_flg_regular_interval_edit  := l_flg_regular_interval_edit;
                o_flg_daily_executions_edit  := l_flg_daily_executions_edit;
                o_flg_predef_time_sched_edit := l_flg_predef_time_sched_edit;
                o_flg_exec_time_edit         := l_flg_exec_time_edit;
                o_flg_repeat_every_edit      := l_flg_repeat_every_edit;
                o_flg_repeat_by_edit         := l_flg_repeat_by_edit;
                o_flg_start_date_edit        := l_flg_start_date_edit;
                o_flg_end_by_edit            := l_flg_end_by_edit;
                o_flg_end_after_edit         := l_flg_end_after_edit;
                o_flg_week_day_edit          := l_flg_week_day_edit;
                o_flg_week_edit              := l_flg_week_edit;
                o_flg_month_day_edit         := l_flg_month_day_edit;
                o_flg_month_edit             := l_flg_month_edit;
                o_flg_ok_avail               := l_flg_ok_avail;
            END IF;
        END LOOP;
    
        g_error := 'OPEN O_EXEC_TIMES';
        OPEN o_exec_times FOR
            SELECT num_1 id_order_recurr_plan,
                   num_2 exec_time_parent_option,
                   num_3 exec_time_option,
                   vc_1  exec_time,
                   vc_2  exec_time_desc
              FROM tbl_temp;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_ORDER_RECURR_OPTION',
                                              o_error);
            pk_types.open_my_cursor(o_exec_times);
            RETURN FALSE;
    END check_order_recurr_option;

    FUNCTION get_order_recurr_plan_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        -- get order recurrence plan frequency description
        RETURN pk_order_recurrence_core.get_order_recurr_plan_desc(i_lang              => i_lang,
                                                                   i_prof              => i_prof,
                                                                   i_order_recurr_plan => i_order_recurr_plan);
    END get_order_recurr_plan_desc;

    FUNCTION get_order_recurr_instructions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_order_plan          IN order_recurr_plan.id_order_recurr_plan%TYPE,
        o_order_recurr_desc   OUT VARCHAR2,
        o_order_recurr_option OUT order_recurr_plan.id_order_recurr_option%TYPE,
        o_start_date          OUT VARCHAR2,
        o_occurrences         OUT order_recurr_plan.occurrences%TYPE,
        o_duration            OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration  OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_duration_desc       OUT VARCHAR2,
        o_end_date            OUT VARCHAR2,
        o_flg_end_by_editable OUT VARCHAR2,
        o_order_recurr_plan   OUT order_recurr_plan.id_order_recurr_plan%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
        -- call pk_order_recurrence_core.get_order_recurr_instructions function
        IF NOT pk_order_recurrence_core.get_order_recurr_instructions(i_lang                => i_lang,
                                                                      i_prof                => i_prof,
                                                                      i_order_plan          => i_order_plan,
                                                                      o_order_recurr_desc   => o_order_recurr_desc,
                                                                      o_order_recurr_option => o_order_recurr_option,
                                                                      o_start_date          => l_start_date,
                                                                      o_occurrences         => o_occurrences,
                                                                      o_duration            => o_duration,
                                                                      o_unit_meas_duration  => o_unit_meas_duration,
                                                                      o_end_date            => l_end_date,
                                                                      o_flg_end_by_editable => o_flg_end_by_editable,
                                                                      o_error               => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.get_order_recurr_instructions function';
            RAISE e_user_exception;
        END IF;
    
        -- convert start date and end date to the format supported by the Flash layer
        o_start_date := pk_date_utils.date_send_tsz(i_lang, l_start_date, i_prof);
        o_end_date   := pk_date_utils.date_send_tsz(i_lang, l_end_date, i_prof);
    
        -- process duration description
        IF o_duration IS NOT NULL
        THEN
            o_duration_desc := o_duration || ' ' ||
                               pk_unit_measure.get_unit_measure_description(i_lang, i_prof, o_unit_meas_duration);
        END IF;
    
        -- assign remain output variables
        o_order_recurr_plan := i_order_plan;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORDER_RECURR_INSTRUCTIONS',
                                              o_error);
            RETURN FALSE;
    END get_order_recurr_instructions;

    FUNCTION get_order_recurr_instructions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_order_recurr_plan   IN table_number,
        o_order_recurr_plan   OUT table_number,
        o_order_recurr_desc   OUT table_varchar,
        o_order_recurr_option OUT table_number,
        o_start_date          OUT table_varchar,
        o_occurrences         OUT table_number,
        o_duration            OUT table_number,
        o_unit_meas_duration  OUT table_number,
        o_duration_desc       OUT table_varchar,
        o_end_date            OUT table_varchar,
        o_flg_end_by_editable OUT table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_order_recurr_desc   VARCHAR2(1000 CHAR);
        l_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
        l_start_date          order_recurr_plan.start_date%TYPE;
        l_occurrences         order_recurr_plan.occurrences%TYPE;
        l_duration            order_recurr_plan.duration%TYPE;
        l_unit_meas_duration  order_recurr_plan.id_unit_meas_duration%TYPE;
        l_end_date            order_recurr_plan.end_date%TYPE;
        l_flg_end_by_editable VARCHAR2(1 CHAR);
    
    BEGIN
    
        IF i_order_recurr_plan IS NULL
           OR i_order_recurr_plan.count = 0
        THEN
            g_error := 'order recurrence plan ids cannot be empty';
            RAISE e_user_exception;
        END IF;
    
        o_order_recurr_plan   := table_number();
        o_order_recurr_desc   := table_varchar();
        o_order_recurr_option := table_number();
        o_start_date          := table_varchar();
        o_occurrences         := table_number();
        o_duration            := table_number();
        o_unit_meas_duration  := table_number();
        o_duration_desc       := table_varchar();
        o_end_date            := table_varchar();
        o_flg_end_by_editable := table_varchar();
    
        g_error := 'FOR i IN 1 .. ' || i_order_recurr_plan.count;
        FOR i IN 1 .. i_order_recurr_plan.count
        LOOP
            -- call pk_order_recurrence_core.get_order_recurr_instructions function
            IF NOT pk_order_recurrence_core.get_order_recurr_instructions(i_lang                => i_lang,
                                                                          i_prof                => i_prof,
                                                                          i_order_plan          => i_order_recurr_plan(i),
                                                                          o_order_recurr_desc   => l_order_recurr_desc,
                                                                          o_order_recurr_option => l_order_recurr_option,
                                                                          o_start_date          => l_start_date,
                                                                          o_occurrences         => l_occurrences,
                                                                          o_duration            => l_duration,
                                                                          o_unit_meas_duration  => l_unit_meas_duration,
                                                                          o_end_date            => l_end_date,
                                                                          o_flg_end_by_editable => l_flg_end_by_editable,
                                                                          o_error               => o_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.get_order_recurr_instructions function';
                RAISE e_user_exception;
            END IF;
        
            o_order_recurr_desc.extend;
            o_order_recurr_option.extend;
            o_start_date.extend;
            o_occurrences.extend;
            o_duration.extend;
            o_unit_meas_duration.extend;
            o_duration_desc.extend;
            o_end_date.extend;
            o_flg_end_by_editable.extend;
            o_order_recurr_plan.extend;
        
            -- assign output variable
            o_order_recurr_plan(i) := i_order_recurr_plan(i);
        
            o_order_recurr_desc(i) := l_order_recurr_desc;
            o_order_recurr_option(i) := l_order_recurr_option;
        
            o_start_date(i) := pk_date_utils.date_send_tsz(i_lang, l_start_date, i_prof);
            o_end_date(i) := pk_date_utils.date_send_tsz(i_lang, l_end_date, i_prof);
        
            o_flg_end_by_editable(i) := l_flg_end_by_editable;
            o_occurrences(i) := l_occurrences;
            o_duration(i) := l_duration;
            o_unit_meas_duration(i) := l_unit_meas_duration;
        
            IF l_duration IS NOT NULL
            THEN
                o_duration_desc(i) := l_duration || ' ' ||
                                      pk_unit_measure.get_unit_measure_description(i_lang, i_prof, l_unit_meas_duration);
            END IF;
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
                                              'GET_ORDER_RECURR_INSTRUCTIONS',
                                              o_error);
            RETURN FALSE;
    END get_order_recurr_instructions;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_order_recurrence_api_ux;
/
