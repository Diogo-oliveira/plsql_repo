/*-- Last Change Revision: $Rev: 2028822 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:09 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_order_recurrence_api_ux IS

    -- purpose: order recurrence UX api database package

    /********************************************************************************************
    * get predefined time schedules
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_order_recurr_area      order recurrence area internal name
    * @param       o_predef_time_schedules  cursor with the predefined time schedules
    * @param       o_error                  error structure for exception handling
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Tiago Silva
    * @since                                20-APR-2011
    ********************************************************************************************/
    FUNCTION get_predefined_time_schedules
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_order_recurr_area     IN order_recurr_area.internal_name%TYPE,
        o_predef_time_schedules OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get most frequent recurrences
    *
    * @param       i_lang                  preferred language id
    * @param       i_prof                  professional structure
    * @param       i_order_recurr_area     order recurrence area internal name
    * @param       o_order_recurr_options  cursor with the most frequent order recurrence options
    * @param       o_error                 error structure for exception handling
    *
    * @return      boolean                 true on success, otherwise false
    *
    * @author                              Tiago Silva
    * @since                               20-APR-2011
    ********************************************************************************************/
    FUNCTION get_most_frequent_recurrences
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_order_recurr_area    IN order_recurr_area.internal_name%TYPE,
        o_order_recurr_options OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_order_recurr_plan_end
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_domain            IN VARCHAR2,
        i_flg_context       IN VARCHAR2,
        o_domains           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_order_recurr_plan_end
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_domain      IN VARCHAR2,
        i_flg_context IN VARCHAR2,
        o_domains     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * create a temporary order recurrence plan based on the default order recurrence option
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_order_recurr_area      order recurrence area internal name
    * @param       o_order_recurr_desc      order recurrence description
    * @param       o_order_recurr_option    default order recurrence option id
    * @param       o_start_date             calculated order start date
    * @param       o_ocurrences             number of occurrences considered in this plan
    * @param       o_duration               duration considered in this plan
    * @param       o_unit_meas_duration     duration unit measure considered in this plan
    * @param       o_duration_desc          duration description
    * @param       o_end_date               calculated order plan end date
    * @param       o_flg_end_by_editable    flag that indicates if "executions", "duration" and "end date" fields must be editable or not
    * @param       o_order_recurr_plan      generated order recurrence plan id
    * @param       o_error                  error structure for exception handling
    *
    * @value       o_flg_end_by_editable    {*} 'Y' "executions", "duration" and "end date" fields must be editable
    *                                       {*} 'N' "executions", "duration" and "end date" fields must be not editable
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Tiago Silva
    * @since                                26-APR-2011
    ********************************************************************************************/
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
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * create a predefined order recurrence plan based on the default order recurrence option
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_order_recurr_area      order recurrence area internal name
    * @param       i_num_task_reqs          number of tasks requests that requires order recurrence plan
    * @param       o_order_recurr_desc      order recurrence description
    * @param       o_order_recurr_option    default order recurrence option id
    * @param       o_start_date             calculated order start date
    * @param       o_ocurrences             number of occurrences considered in this plan
    * @param       o_duration               duration considered in this plan
    * @param       o_unit_meas_duration     duration unit measure considered in this plan
    * @param       o_duration_desc          duration description
    * @param       o_end_date               calculated order plan end date
    * @param       o_flg_end_by_editable    flag that indicates if "executions", "duration" and "end date" fields must be editable or not
    * @param       o_order_recurr_plans     array of generated order recurrence plan ids
    * @param       o_error                  error structure for exception handling
    *
    * @value       o_flg_end_by_editable    {*} 'Y' "executions", "duration" and "end date" fields must be editable
    *                                       {*} 'N' "executions", "duration" and "end date" fields must be not editable
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Ana Monteiro
    * @since                                04-JUN-2014
    ********************************************************************************************/
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
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * copy an existing temporary order recurrence plan
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_order_recurr_plan_from existing order recurrence plan to copy from
    * @param       o_order_recurr_desc      order recurrence description
    * @param       o_order_recurr_option    default order recurrence option id
    * @param       o_start_date             calculated order start date
    * @param       o_ocurrences             number of occurrences considered in this plan
    * @param       o_duration               duration considered in this plan
    * @param       o_unit_meas_duration     duration unit measure considered in this plan
    * @param       o_duration_desc          duration description
    * @param       o_end_date               calculated order plan end date
    * @param       o_flg_end_by_editable    flag that indicates if "executions", "duration" and "end date" fields must be editable or not
    * @param       o_order_recurr_plan      new order recurrence plan id for created copy
    * @param       o_error                  error structure for exception handling
    *
    * @value       o_flg_end_by_editable    {*} 'Y' "executions", "duration" and "end date" fields must be editable
    *                                       {*} 'N' "executions", "duration" and "end date" fields must be not editable
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Carlos Loureiro
    * @since                                29-APR-2011
    ********************************************************************************************/
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
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * edit from existing order recurrence plan, with start date and option adjustments (perform a copy from)
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_order_recurr_area      order recurrence area internal name
    * @param       i_order_recurr_option    desired plan recurrence option
    * @param       i_start_date             desired start date plan
    * @param       i_occurrences            number of occurrences defined by the user
    * @param       i_duration               duration defined by the user
    * @param       i_unit_meas_duration     duration unit measure defined by the user
    * @param       i_end_date               order plan end date defined by the user
    * @param       i_order_recurr_plan_from order recurrence plan to copy from
    * @param       o_order_recurr_desc      order recurrence description
    * @param       o_order_recurr_option    default order recurrence option id
    * @param       o_start_date             calculated order start date
    * @param       o_ocurrences             number of occurrences considered in this plan
    * @param       o_duration               duration considered in this plan
    * @param       o_unit_meas_duration     duration unit measure considered in this plan
    * @param       o_duration_desc          duration description
    * @param       o_end_date               calculated order plan end date
    * @param       o_flg_end_by_editable    flag that indicates if "executions", "duration" and "end date" fields must be editable or not
    * @param       o_order_recurr_plan      new order recurrence plan id for created copy
    * @param       o_error                  error structure for exception handling
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @value       o_flg_end_by_editable    {*} 'Y' "executions", "duration" and "end date" fields must be editable
    *                                       {*} 'N' "executions", "duration" and "end date" fields must be not editable
    *
    * @author                               Carlos Loureiro
    * @since                                26-OCT-2011
    ********************************************************************************************/
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
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set a new order recurrence option for a given order recurrence plan
    *
    * @param       i_lang                         preferred language id
    * @param       i_prof                         professional structure
    * @param       i_order_recurr_plan            order recurrence plan id
    * @param       i_order_recurr_option          order recurrence option id
    * @param       o_order_recurr_desc            order recurrence description
    * @param       o_order_recurr_option          order recurrence option id
    * @param       o_start_date                   calculated order start date
    * @param       o_ocurrences                   number of occurrences considered in this plan
    * @param       o_duration                     duration considered in this plan
    * @param       o_unit_meas_duration           duration unit measure considered in this plan
    * @param       o_duration_desc                duration description
    * @param       o_end_date                     calculated order plan end date
    * @param       o_flg_end_by_editable          flag that indicates if "executions", "duration" and "end date" fields must be editable or not
    * @param       o_order_recurr_plan            order recurrence plan id
    * @param       o_error                        error structure for exception handling
    *
    * @value       o_flg_end_by_editable          {*} 'Y' "executions", "duration" and "end date" fields must be editable
    *                                             {*} 'N' "executions", "duration" and "end date" fields must be not editable
    *
    * @return      boolean                        true on success, otherwise false
    *
    * @author                                     Tiago Silva
    * @since                                      26-APR-2011
    ********************************************************************************************/
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
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set a new order recurrence option for an array of order recurrence plan
    *
    * @param       i_lang                         preferred language id
    * @param       i_prof                         professional structure
    * @param       i_order_recurr_plans           array of order recurrence plan ids
    * @param       i_order_recurr_option          order recurrence option id
    * @param       o_order_recurr_desc            order recurrence description
    * @param       o_order_recurr_option          order recurrence option id
    * @param       o_start_date                   calculated order start date
    * @param       o_ocurrences                   number of occurrences considered in this plan
    * @param       o_duration                     duration considered in this plan
    * @param       o_unit_meas_duration           duration unit measure considered in this plan
    * @param       o_duration_desc                duration description
    * @param       o_end_date                     calculated order plan end date
    * @param       o_flg_end_by_editable          flag that indicates if "executions", "duration" and "end date" fields must be editable or not
    * @param       o_order_recurr_plans           array of order recurrence plan ids
    * @param       o_error                        error structure for exception handling
    *
    * @value       o_flg_end_by_editable          {*} 'Y' "executions", "duration" and "end date" fields must be editable
    *                                             {*} 'N' "executions", "duration" and "end date" fields must be not editable
    *
    * @return      boolean                        true on success, otherwise false
    *
    * @author                                     Tiago Silva
    * @since                                      26-APR-2011
    ********************************************************************************************/
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
    ) RETURN BOOLEAN;

    /*
    * Sets a new order recurrence option for an array of order recurrence plan
    *
    * @param     i_lang                  Language id
    * @param     i_prof                  Professional
    * @param     i_order_recurr_plan     Order recurrence plan ids
    * @param     i_order_recurr_option   Order recurrence option id
    * @param     o_order_recurr_plan     Order recurrence plan ids
    * @param     o_order_recurr_desc     Order recurrence description
    * @param     o_order_recurr_option   Order recurrence option id
    * @param     o_start_date            Calculated order start date
    * @param     o_ocurrences            Number of occurrences considered in this plan
    * @param     o_duration              Duration considered in this plan
    * @param     o_unit_meas_duration    Duration unit measure considered in this plan
    * @param     o_duration_desc         Duration description
    * @param     o_end_date              Calculated order plan end date
    * @param     o_flg_end_by_editable   Flag that indicates if "executions", "duration" and "end date" fields must be editable or not
    * @param     o_error                 Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.5
    * @since     2015/12/01
    */

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
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set new order recurrence instructions for a given order recurrence plan
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_order_recurr_plan      order recurrence plan id
    * @param       i_start_date             order start date defined by the user
    * @param       i_occurrences            number of occurrences defined by the user
    * @param       i_duration               duration defined by the user
    * @param       i_unit_meas_duration     duration unit measure defined by the user
    * @param       i_end_date               order plan end date defined by the user
    * @param       o_order_recurr_desc      order recurrence description
    * @param       o_order_recurr_option    order recurrence option id
    * @param       o_start_date             calculated order start date
    * @param       o_ocurrences             number of occurrences considered in this plan
    * @param       o_duration               duration considered in this plan
    * @param       o_unit_meas_duration     duration unit measure considered in this plan
    * @param       o_duration_desc          duration description
    * @param       o_end_date               calculated order plan end date
    * @param       o_flg_end_by_editable    flag that indicates if "executions", "duration" and "end date" fields must be editable or not
    * @param       o_order_recurr_plan      order recurrence plan id
    * @param       o_error                  error structure for exception handling
    *
    * @value       o_flg_end_by_editable    {*} 'Y' "executions", "duration" and "end date" fields must be editable
    *                                       {*} 'N' "executions", "duration" and "end date" fields must be not editable
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Tiago Silva
    * @since                                26-APR-2011
    ********************************************************************************************/
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
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set new order recurrence instructions for an array of order recurrence plans
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_order_recurr_plans     array of order recurrence plan ids
    * @param       i_start_date             order start date defined by the user
    * @param       i_occurrences            number of occurrences defined by the user
    * @param       i_duration               duration defined by the user
    * @param       i_unit_meas_duration     duration unit measure defined by the user
    * @param       i_end_date               order plan end date defined by the user
    * @param       o_order_recurr_desc      order recurrence description
    * @param       o_order_recurr_option    order recurrence option id
    * @param       o_start_date             calculated order start date
    * @param       o_ocurrences             number of occurrences considered in this plan
    * @param       o_duration               duration considered in this plan
    * @param       o_unit_meas_duration     duration unit measure considered in this plan
    * @param       o_duration_desc          duration description
    * @param       o_end_date               calculated order plan end date
    * @param       o_flg_end_by_editable    flag that indicates if "executions", "duration" and "end date" fields must be editable or not
    * @param       o_order_recurr_plans     array of order recurrence plan ids
    * @param       o_error                  error structure for exception handling
    *
    * @value       o_flg_end_by_editable    {*} 'Y' "executions", "duration" and "end date" fields must be editable
    *                                       {*} 'N' "executions", "duration" and "end date" fields must be not editable
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Tiago Silva
    * @since                                26-APR-2011
    ********************************************************************************************/
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
    ) RETURN BOOLEAN;

    /*
    * Sets new order recurrence instructions for an array of order recurrence plans
    *
    * @param     i_lang                  Language id
    * @param     i_prof                  Professional
    * @param     i_order_recurr_plans    Order recurrence plan ids
    * @param     i_start_date            Order start date defined by the user
    * @param     i_occurrences           Number of occurrences defined by the user
    * @param     i_duration              Duration defined by the user
    * @param     i_unit_meas_duration    Duration unit measure defined by the user
    * @param     i_end_date              Order plan end date defined by the user
    * @param     o_order_recurr_plan     Order recurrence plan ids
    * @param     o_order_recurr_desc     Order recurrence description
    * @param     o_order_recurr_option   Order recurrence option id
    * @param     o_start_date            Calculated order start date
    * @param     o_ocurrences            Number of occurrences considered in this plan
    * @param     o_duration              Duration considered in this plan
    * @param     o_unit_meas_duration    Duration unit measure considered in this plan
    * @param     o_duration_desc         Duration description
    * @param     o_end_date              Calculated order plan end date
    * @param     o_flg_end_by_editable   Flag that indicates if "executions", "duration" and "end date" fields must be editable or not
    * @param     o_error                 Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.5
    * @since     2015/12/01
    */

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
    ) RETURN BOOLEAN;

    FUNCTION set_order_recurr_instructions
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_order_recurr_plan    IN table_number,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_val              IN table_table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set a new order recurrence option for a given order recurrence plan
    *
    * @param       i_lang                           preferred language id
    * @param       i_prof                           professional structure
    * @param       i_order_recurr_plan              order recurrence plan id
    * @param       i_regular_interval               regular interval
    * @param       i_unit_meas_regular_interval     regular interval unit measure
    * @param       i_daily_executions               number of daily executions
    * @param       i_predef_time_sched              predefined time schedules ids
    * @param       i_exec_time_parent_option        array of execution time parent options (predefined time schedules options)
    * @param       i_exec_time_option               array of execution time options
    * @param       i_exec_time                      array of exec times
    * @param       i_exec_time_offset               array of exec time offsets
    * @param       i_unit_meas_exec_time_offset     array of exec time offsets unit measures
    * @param       i_flg_recurr_pattern             flag that indicates the recurrence pattern
    * @param       i_repeat_every                   recurrence frequency
    * @param       i_flg_repeat_by                  flag that indicates if the recurrence pattern must be repeated by month days or week days
    * @param       i_start_date                     order start date defined by the user
    * @param       i_flg_end_by                     flag that indicates which parameter must be considered to calculate the recurrence end date
    * @param       i_occurrences                    number of occurrences
    * @param       i_duration                       duration
    * @param       i_unit_meas_duration             duration unit measure
    * @param       i_end_date                       order end date
    * @param       i_flg_week_day                   array of week day options
    * @param       i_flg_week                       array of week options
    * @param       i_month_day                      array of month day options
    * @param       i_month                          array of month options
    * @param       o_order_recurr_desc              order recurrence description
    * @param       o_order_recurr_option            order recurrence option id
    * @param       o_start_date                     calculated order start date
    * @param       o_ocurrences                     number of occurrences considered in this plan
    * @param       o_duration                       duration considered in this plan
    * @param       o_unit_meas_duration             duration unit measure considered in this plan
    * @param       o_duration_desc                  duration description
    * @param       o_end_date                       calculated order plan end date
    * @param       o_flg_end_by_editable            flag that indicates if "executions", "duration" and "end date" fields must be editable or not
    * @param       o_order_recurr_plan              order recurrence plan id
    * @param       o_error                          error structure for exception handling
    *
    * @value       i_flg_recurr_pattern             {*} '0' without recurrence
    *                                               {*} 'D' daily
    *                                               {*} 'W' weekly
    *                                               {*} 'M' monthly
    *                                               {*} 'Y' yearly
    *
    * @value       i_flg_recurr_pattern             {*} 'M' month days
    *                                               {*} 'W' week days
    *
    * @value       i_flg_end_by                     {*} 'D' date
    *                                               {*} 'W' without end date
    *                                               {*} 'N' number of executions
    *                                               {*} 'L' duration
    *
    * @value       i_flg_week_day                   {*} 1 Sunday
    *                                               {*} 2 Monday
    *                                               {*} 3 Tuesday
    *                                               {*} 4 Wednesday
    *                                               {*} 5 Thursday
    *                                               {*} 6 Friday
    *                                               {*} 7 Saturday
    *
    * @value       i_flg_week                       {*} 1 first
    *                                               {*} 2 second
    *                                               {*} 3 third
    *                                               {*} 4 fourth
    *                                               {*} 5 last
    *
    * @value       o_flg_end_by_editable            {*} 'Y' "executions", "duration" and "end date" fields must be editable
    *                                               {*} 'N' "executions", "duration" and "end date" fields must be not editable
    *
    * @return      boolean                          true on success, otherwise false
    *
    * @author                                       Tiago Silva
    * @since                                        26-APR-2011
    ********************************************************************************************/
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
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set a new order recurrence option for a given order recurrence plan
    *
    * @param       i_lang                           preferred language id
    * @param       i_prof                           professional structure
    * @param       i_order_recurr_plans             array of order recurrence plan ids
    * @param       i_regular_interval               regular interval
    * @param       i_unit_meas_regular_interval     regular interval unit measure
    * @param       i_daily_executions               number of daily executions
    * @param       i_predef_time_sched              predefined time schedules ids
    * @param       i_exec_time_parent_option        array of execution time parent options (predefined time schedules options)
    * @param       i_exec_time_option               array of execution time options
    * @param       i_exec_time                      array of exec times
    * @param       i_exec_time_offset               array of exec time offsets
    * @param       i_unit_meas_exec_time_offset     array of exec time offsets unit measures
    * @param       i_flg_recurr_pattern             flag that indicates the recurrence pattern
    * @param       i_repeat_every                   recurrence frequency
    * @param       i_flg_repeat_by                  flag that indicates if the recurrence pattern must be repeated by month days or week days
    * @param       i_start_date                     order start date defined by the user
    * @param       i_flg_end_by                     flag that indicates which parameter must be considered to calculate the recurrence end date
    * @param       i_occurrences                    number of occurrences
    * @param       i_duration                       duration
    * @param       i_unit_meas_duration             duration unit measure
    * @param       i_end_date                       order end date
    * @param       i_flg_week_day                   array of week day options
    * @param       i_flg_week                       array of week options
    * @param       i_month_day                      array of month day options
    * @param       i_month                          array of month options
    * @param       i_flg_context                    flag that indicates the application context where this function is being called
    * @param       o_order_recurr_desc              order recurrence description
    * @param       o_order_recurr_option            order recurrence option id
    * @param       o_start_date                     calculated order start date
    * @param       o_ocurrences                     number of occurrences considered in this plan
    * @param       o_duration                       duration considered in this plan
    * @param       o_unit_meas_duration             duration unit measure considered in this plan
    * @param       o_duration_desc                  duration description
    * @param       o_end_date                       calculated order plan end date
    * @param       o_flg_end_by_editable            flag that indicates if "executions", "duration" and "end date" fields must be editable or not
    * @param       o_order_recurr_plans             array of generated order recurrence plan ids
    * @param       o_error                          error structure for exception handling
    *
    * @value       i_flg_recurr_pattern             {*} '0' without recurrence
    *                                               {*} 'D' daily
    *                                               {*} 'W' weekly
    *                                               {*} 'M' monthly
    *                                               {*} 'Y' yearly
    *
    * @value       i_flg_recurr_pattern             {*} 'M' month days
    *                                               {*} 'W' week days
    *
    * @value       i_flg_end_by                     {*} 'D' date
    *                                               {*} 'W' without end date
    *                                               {*} 'N' number of executions
    *                                               {*} 'L' duration
    *
    * @value       i_flg_week_day                   {*} 1 Sunday
    *                                               {*} 2 Monday
    *                                               {*} 3 Tuesday
    *                                               {*} 4 Wednesday
    *                                               {*} 5 Thursday
    *                                               {*} 6 Friday
    *                                               {*} 7 Saturday
    *
    * @value       i_flg_week                       {*} 1 first
    *                                               {*} 2 second
    *                                               {*} 3 third
    *                                               {*} 4 fourth
    *                                               {*} 5 last
    *
    * @value       i_flg_context                    {*} 'S' settings context
    *                                               {*} 'P' patient context
    *
    * @value       o_flg_end_by_editable            {*} 'Y' "executions", "duration" and "end date" fields must be editable
    *                                               {*} 'N' "executions", "duration" and "end date" fields must be not editable
    *
    * @return      boolean                          true on success, otherwise false
    *
    * @author                                       Tiago Silva
    * @since                                        26-APR-2011
    ********************************************************************************************/
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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set a temporary order recurrence plan as definitive (final status)
    *
    * @param       i_lang                      preferred language id
    * @param       i_prof                      professional structure
    * @param       i_order_recurr_plan         order recurrence plan id
    * @param       o_order_recurr_option       order recurrence option id
    * @param       o_final_order_recurr_plan   final order recurrence plan id
    * @param       o_error                     error structure for exception handling
    *
    * @return      boolean                     true on success, otherwise false
    *
    * @author                                  Tiago Silva
    * @since                                   26-APR-2011
    ********************************************************************************************/
    FUNCTION set_order_recurr_plan
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_order_recurr_plan       IN order_recurr_plan.id_order_recurr_plan%TYPE,
        o_order_recurr_option     OUT order_recurr_plan.id_order_recurr_option%TYPE,
        o_final_order_recurr_plan OUT order_recurr_plan.id_order_recurr_plan%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * cancel a temporary order recurrence plan
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_order_recurr_plan      order recurrence plan id
    * @param       o_error                  error structure for exception handling
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Tiago Silva
    * @since                                26-APR-2011
    ********************************************************************************************/
    FUNCTION cancel_order_recurr_plan
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * cancel temporary order recurrence plans
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_order_recurr_plans     array of order recurrence plan ids
    * @param       o_error                  error structure for exception handling
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Tiago Silva
    * @since                                26-APR-2011
    ********************************************************************************************/
    FUNCTION cancel_order_recurr_plan
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_order_recurr_plans IN table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get other order recurrence option data
    *
    * @param       i_lang                           preferred language id
    * @param       i_prof                           professional structure
    * @param       i_order_recurr_plan              order recurrence plan id
    * @param       i_flg_context                    flag that indicates the application context where this function is being called
    * @param       o_regular_interval               regular interval
    * @param       o_unit_meas_regular_interval     regular interval unit measure
    * @param       o_regular_interval_desc          regular interval description
    * @param       o_daily_executions               number of daily executions
    * @param       o_predef_time_sched              predefined time schedules ids
    * @param       o_predef_time_sched_desc         predefined time schedule field description
    * @param       o_exec_times                     cursor of execution times
    * @param       o_flg_recurr_pattern             flag that indicates the recurrence pattern
    * @param       o_recurr_pattern_desc            recurrence pattern description
    * @param       o_repeat_every                   recurrence frequency
    * @param       o_unit_meas_repeat_every         recurrence frequency unit measure
    * @param       o_repeat_every_desc              recurrence frequency description
    * @param       o_flg_repeat_by                  flag that indicates if the recurrence pattern must be repeated by month days or week days
    * @param       o_repeat_by_desc                 "repeat by" field description
    * @param       o_start_date                     order start date defined by the user
    * @param       o_flg_end_by                     flag that indicates which parameter must be considered to calculate the recurrence end date
    * @param       o_end_by_desc                    "end by" field description
    * @param       o_occurrences                    number of occurrences
    * @param       o_duration                       duration
    * @param       o_unit_meas_duration             duration unit measure
    * @param       o_end_date                       order end date
    * @param       o_end_after_desc                 "end after" field description
    * @param       o_flg_week_day                   array of week day options
    * @param       o_week_day_desc                  "week day" field description
    * @param       o_flg_week                       array of week options
    * @param       o_week_desc                      "week" field description
    * @param       o_month_day                      array of month day options
    * @param       o_month                          array of month options
    * @param       o_month_desc                     "month" field description
    * @param       o_flg_regular_interval_edit      flag that indicates if regular interval field must be editable or not
    * @param       o_flg_daily_executions_edit      flag that indicates if daily executions field must be editable or not
    * @param       o_flg_predef_time_sched_edit     flag that indicates if predefined time schedules field must be editable or not
    * @param       o_flg_exec_time_edit             flag that indicates if execution times fields must be editable or not
    * @param       o_flg_repeat_every_edit          flag that indicates if "repeat every" field must be editable or not
    * @param       o_flg_repeat_by_edit             flag that indicates if "repeat by" field must be editable or not
    * @param       o_flg_start_date_edit            flag that indicates if start date field must be editable or not
    * @param       o_flg_end_by_edit                flag that indicates if "end by" field must be editable or not
    * @param       o_flg_end_after_edit             flag that indicates if "end after" field must be editable or not
    * @param       o_flg_week_day_edit              flag that indicates if "week day" field must be editable or not
    * @param       o_flg_week_edit                  flag that indicates if "week" field must be editable or not
    * @param       o_flg_month_day_edit             flag that indicates if "month day" field must editable or not
    * @param       o_flg_month_edit                 flag that indicates if "month" field must editable or not
    * @param       o_flg_ok_avail                   flag that indicates if ok button must be available or not
    * @param       o_error                          error structure for exception handling
    *
    * @value       i_flg_context                    {*} 'S' settings context
    *                                               {*} 'P' patient context
    *
    * @value       o_flg_recurr_pattern             {*} '0' without recurrence
    *                                               {*} 'D' daily
    *                                               {*} 'W' weekly
    *                                               {*} 'M' monthly
    *                                               {*} 'Y' yearly
    *
    * @value       o_flg_recurr_pattern             {*} 'M' month days
    *                                               {*} 'W' week days
    *
    * @value       o_flg_end_by                     {*} 'D' date
    *                                               {*} 'W' without end date
    *                                               {*} 'N' number of executions
    *                                               {*} 'L' duration
    *
    * @value       o_flg_week_day                   {*} 1 Sunday
    *                                               {*} 2 Monday
    *                                               {*} 3 Tuesday
    *                                               {*} 4 Wednesday
    *                                               {*} 5 Thursday
    *                                               {*} 6 Friday
    *                                               {*} 7 Saturday
    *
    * @value       o_flg_week                       {*} 1 first
    *                                               {*} 2 second
    *                                               {*} 3 third
    *                                               {*} 4 fourth
    *                                               {*} 5 last
    *
    * @value       o_flg_regular_interval_edit      {*} 'Y' regular interval field must be editable
    *                                               {*} 'N' regular interval field must be not editable
    *
    * @value       o_flg_daily_executions_edit      {*} 'Y' daily executions field must be editable
    *                                               {*} 'N' daily executions field must be not editable
    *
    * @value       o_flg_predef_time_sched_edit     {*} 'Y' predefined time schedules field field must be editable
    *                                               {*} 'N' predefined time schedules field field must be not editable
    *
    * @value       o_flg_exec_time_edit             {*} 'Y' execution times fields must be editable
    *                                               {*} 'N' execution times fields must be not editable
    *
    * @value       o_flg_repeat_every_edit          {*} 'Y' "repeat every" field must be editable
    *                                               {*} 'N' "repeat every" field must be not editable
    *
    * @value       o_flg_repeat_by_edit             {*} 'Y' "repeat by" field must be editable
    *                                               {*} 'N' "repeat by" field must be not editable
    *
    * @value       o_flg_start_date_edit            {*} 'Y' start date field must be editable
    *                                               {*} 'N' start date field must be not editable
    *
    * @value       o_flg_end_by_edit                {*} 'Y' "end by" field must be editable
    *                                               {*} 'N' "end by" field must be not editable
    *
    * @value       o_flg_end_after_edit             {*} 'Y' "end after" field must be editable
    *                                               {*} 'N' "end after" field must be not editable
    *
    * @value       o_flg_week_day_edit              {*} 'Y' "week day" field must be editable
    *                                               {*} 'N' "week day" field must be not editable
    *
    * @value       o_flg_week_edit                  {*} 'Y' "week" field must be editable
    *                                               {*} 'N' "week" field must be not editable
    *
    * @value       o_flg_month_day_edit             {*} 'Y' "month day" field must be editable
    *                                               {*} 'N' "month day" field must be not editable
    *
    * @value       o_flg_month_edit                 {*} 'Y' "month" field must be editable
    *                                               {*} 'N' "month" field must be not editable
    *
    * @value       o_flg_ok_avail                   {*} 'Y' ok button must be available
    *                                               {*} 'N' ok bytton must be not available
    *
    * @return      boolean                          true on success, otherwise false
    *
    * @author                                       Tiago Silva
    * @since                                        29-APR-2011
    ********************************************************************************************/
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
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get other order recurrence option data
    *
    * @param       i_lang                           preferred language id
    * @param       i_prof                           professional structure
    * @param       i_order_recurr_plans             array of order recurrence plan ids
    * @param       i_flg_context                    flag that indicates the application context where this function is being called
    * @param       o_regular_interval               regular interval
    * @param       o_unit_meas_regular_interval     regular interval unit measure
    * @param       o_regular_interval_desc          regular interval description
    * @param       o_daily_executions               number of daily executions
    * @param       o_predef_time_sched              predefined time schedules ids
    * @param       o_predef_time_sched_desc         predefined time schedule field description
    * @param       o_exec_times                     cursor of execution times
    * @param       o_flg_recurr_pattern             flag that indicates the recurrence pattern
    * @param       o_recurr_pattern_desc            recurrence pattern description
    * @param       o_repeat_every                   recurrence frequency
    * @param       o_unit_meas_repeat_every         recurrence frequency unit measure
    * @param       o_repeat_every_desc              recurrence frequency description
    * @param       o_flg_repeat_by                  flag that indicates if the recurrence pattern must be repeated by month days or week days
    * @param       o_repeat_by_desc                 "repeat by" field description
    * @param       o_start_date                     order start date defined by the user
    * @param       o_flg_end_by                     flag that indicates which parameter must be considered to calculate the recurrence end date
    * @param       o_end_by_desc                    "end by" field description
    * @param       o_occurrences                    number of occurrences
    * @param       o_duration                       duration
    * @param       o_unit_meas_duration             duration unit measure
    * @param       o_end_date                       order end date
    * @param       o_end_after_desc                 "end after" field description
    * @param       o_flg_week_day                   array of week day options
    * @param       o_week_day_desc                  "week day" field description
    * @param       o_flg_week                       array of week options
    * @param       o_week_desc                      "week" field description
    * @param       o_month_day                      array of month day options
    * @param       o_month                          array of month options
    * @param       o_month_desc                     "month" field description
    * @param       o_flg_regular_interval_edit      flag that indicates if regular interval field must be editable or not
    * @param       o_flg_daily_executions_edit      flag that indicates if daily executions field must be editable or not
    * @param       o_flg_predef_time_sched_edit     flag that indicates if predefined time schedules field must be editable or not
    * @param       o_flg_exec_time_edit             flag that indicates if execution times fields must be editable or not
    * @param       o_flg_repeat_every_edit          flag that indicates if "repeat every" field must be editable or not
    * @param       o_flg_repeat_by_edit             flag that indicates if "repeat by" field must be editable or not
    * @param       o_flg_start_date_edit            flag that indicates if start date field must be editable or not
    * @param       o_flg_end_by_edit                flag that indicates if "end by" field must be editable or not
    * @param       o_flg_end_after_edit             flag that indicates if "end after" field must be editable or not
    * @param       o_flg_week_day_edit              flag that indicates if "week day" field must be editable or not
    * @param       o_flg_week_edit                  flag that indicates if "week" field must be editable or not
    * @param       o_flg_month_day_edit             flag that indicates if "month day" field must editable or not
    * @param       o_flg_month_edit                 flag that indicates if "month" field must editable or not
    * @param       o_flg_ok_avail                   flag that indicates if ok button must be available or not
    * @param       o_error                          error structure for exception handling
    *
    * @value       i_flg_context                    {*} 'S' settings context
    *                                               {*} 'P' patient context
    *
    * @value       o_flg_recurr_pattern             {*} '0' without recurrence
    *                                               {*} 'D' daily
    *                                               {*} 'W' weekly
    *                                               {*} 'M' monthly
    *                                               {*} 'Y' yearly
    *
    * @value       o_flg_recurr_pattern             {*} 'M' month days
    *                                               {*} 'W' week days
    *
    * @value       o_flg_end_by                     {*} 'D' date
    *                                               {*} 'W' without end date
    *                                               {*} 'N' number of executions
    *                                               {*} 'L' duration
    *
    * @value       o_flg_week_day                   {*} 1 Sunday
    *                                               {*} 2 Monday
    *                                               {*} 3 Tuesday
    *                                               {*} 4 Wednesday
    *                                               {*} 5 Thursday
    *                                               {*} 6 Friday
    *                                               {*} 7 Saturday
    *
    * @value       o_flg_week                       {*} 1 first
    *                                               {*} 2 second
    *                                               {*} 3 third
    *                                               {*} 4 fourth
    *                                               {*} 5 last
    *
    * @value       o_flg_regular_interval_edit      {*} 'Y' regular interval field must be editable
    *                                               {*} 'N' regular interval field must be not editable
    *
    * @value       o_flg_daily_executions_edit      {*} 'Y' daily executions field must be editable
    *                                               {*} 'N' daily executions field must be not editable
    *
    * @value       o_flg_predef_time_sched_edit     {*} 'Y' predefined time schedules field field must be editable
    *                                               {*} 'N' predefined time schedules field field must be not editable
    *
    * @value       o_flg_exec_time_edit             {*} 'Y' execution times fields must be editable
    *                                               {*} 'N' execution times fields must be not editable
    *
    * @value       o_flg_repeat_every_edit          {*} 'Y' "repeat every" field must be editable
    *                                               {*} 'N' "repeat every" field must be not editable
    *
    * @value       o_flg_repeat_by_edit             {*} 'Y' "repeat by" field must be editable
    *                                               {*} 'N' "repeat by" field must be not editable
    *
    * @value       o_flg_start_date_edit            {*} 'Y' start date field must be editable
    *                                               {*} 'N' start date field must be not editable
    *
    * @value       o_flg_end_by_edit                {*} 'Y' "end by" field must be editable
    *                                               {*} 'N' "end by" field must be not editable
    *
    * @value       o_flg_end_after_edit             {*} 'Y' "end after" field must be editable
    *                                               {*} 'N' "end after" field must be not editable
    *
    * @value       o_flg_week_day_edit              {*} 'Y' "week day" field must be editable
    *                                               {*} 'N' "week day" field must be not editable
    *
    * @value       o_flg_week_edit                  {*} 'Y' "week" field must be editable
    *                                               {*} 'N' "week" field must be not editable
    *
    * @value       o_flg_month_day_edit             {*} 'Y' "month day" field must be editable
    *                                               {*} 'N' "month day" field must be not editable
    *
    * @value       o_flg_month_edit                 {*} 'Y' "month" field must be editable
    *                                               {*} 'N' "month" field must be not editable
    *
    * @value       o_flg_ok_avail                   {*} 'Y' ok button must be available
    *                                               {*} 'N' ok bytton must be not available
    *
    * @return      boolean                          true on success, otherwise false
    *
    * @author                                       Tiago Silva
    * @since                                        29-APR-2011
    ********************************************************************************************/
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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * check other order recurrence option data
    *
    * @param       i_lang                           preferred language id
    * @param       i_prof                           professional structure
    * @param       i_order_recurr_plan              order recurrence plan id
    * @param       i_edit_field_name                name of field edited by the user
    * @param       i_regular_interval               regular interval
    * @param       i_unit_meas_regular_interval     regular interval unit measure
    * @param       i_daily_executions               number of daily executions
    * @param       i_predef_time_sched              predefined time schedules ids
    * @param       i_exec_time_parent_option        array of execution time parent options (predefined time schedules options)
    * @param       i_exec_time_option               array of execution time options
    * @param       i_exec_time                      array of exec times
    * @param       i_exec_time_offset               array of exec time offsets
    * @param       i_unit_meas_exec_time_offset     array of exec time offsets unit measures
    * @param       i_flg_recurr_pattern             flag that indicates the recurrence pattern
    * @param       i_repeat_every                   recurrence frequency
    * @param       i_flg_repeat_by                  flag that indicates if the recurrence pattern must be repeated by month days or week days
    * @param       i_start_date                     order start date defined by the user
    * @param       i_flg_end_by                     flag that indicates which parameter must be considered to calculate the recurrence end date
    * @param       i_occurrences                    number of occurrences
    * @param       i_duration                       duration
    * @param       i_unit_meas_duration             duration unit measure
    * @param       i_end_date                       order end date
    * @param       i_flg_week_day                   array of week day options
    * @param       i_flg_week                       array of week options
    * @param       o_regular_interval               regular interval
    * @param       o_unit_meas_regular_interval     regular interval unit measure
    * @param       o_regular_interval_desc          regular interval description
    * @param       o_daily_executions               number of daily executions
    * @param       o_predef_time_sched              predefined time schedules ids
    * @param       o_predef_time_sched_desc         predefined time schedule field description
    * @param       o_exec_times                     cursor of execution times
    * @param       o_flg_recurr_pattern             flag that indicates the recurrence pattern
    * @param       o_recurr_pattern_desc            recurrence pattern description
    * @param       o_repeat_every                   recurrence frequency
    * @param       o_unit_meas_repeat_every         recurrence frequency unit measure
    * @param       o_repeat_every_desc              recurrence frequency description
    * @param       o_flg_repeat_by                  flag that indicates if the recurrence pattern must be repeated by month days or week days
    * @param       o_repeat_by_desc                 "repeat by" field description
    * @param       o_start_date                     order start date defined by the user
    * @param       o_flg_end_by                     flag that indicates which parameter must be considered to calculate the recurrence end date
    * @param       o_end_by_desc                    "end by" field description
    * @param       o_occurrences                    number of occurrences
    * @param       o_duration                       duration
    * @param       o_unit_meas_duration             duration unit measure
    * @param       o_end_date                       order end date
    * @param       o_end_after_desc                 "end after" field description
    * @param       o_flg_week_day                   array of week day options
    * @param       o_week_day_desc                  "week day" field description
    * @param       o_flg_week                       array of week options
    * @param       o_week_desc                      "week" field description
    * @param       o_month_day                      array of month day options
    * @param       o_month                          array of month options
    * @param       o_month_desc                     "month" field description
    * @param       o_flg_regular_interval_edit      flag that indicates if regular interval field must be editable or not
    * @param       o_flg_daily_executions_edit      flag that indicates if daily executions field must be editable or not
    * @param       o_flg_predef_time_sched_edit     flag that indicates if predefined time schedules field must be editable or not
    * @param       o_flg_exec_time_edit             flag that indicates if execution times fields must be editable or not
    * @param       o_flg_repeat_every_edit          flag that indicates if "repeat every" field must be editable or not
    * @param       o_flg_repeat_by_edit             flag that indicates if "repeat by" field must be editable or not
    * @param       o_flg_start_date_edit            flag that indicates if start date field must be editable or not
    * @param       o_flg_end_by_edit                flag that indicates if "end by" field must be editable or not
    * @param       o_flg_end_after_edit             flag that indicates if "end after" field must be editable or not
    * @param       o_flg_week_day_edit              flag that indicates if "week day" field must be editable or not
    * @param       o_flg_week_edit                  flag that indicates if "week" field must be editable or not
    * @param       o_flg_month_day_edit             flag that indicates if "month day" field must editable or not
    * @param       o_flg_month_edit                 flag that indicates if "month" field must editable or not
    * @param       o_flg_ok_avail                   flag that indicates if ok button must be available or not
    * @param       o_error                          error structure for exception handling
    *
    * @value       i_flg_recurr_pattern             {*} '0' without recurrence
    *                                               {*} 'D' daily
    *                                               {*} 'W' weekly
    *                                               {*} 'M' monthly
    *                                               {*} 'Y' yearly
    *
    * @value       i_flg_recurr_pattern             {*} 'M' month days
    *                                               {*} 'W' week days
    *
    * @value       i_flg_end_by                     {*} 'D' date
    *                                               {*} 'W' without end date
    *                                               {*} 'N' number of executions
    *                                               {*} 'L' duration
    *
    * @value       i_flg_week_day                   {*} 1 Sunday
    *                                               {*} 2 Monday
    *                                               {*} 3 Tuesday
    *                                               {*} 4 Wednesday
    *                                               {*} 5 Thursday
    *                                               {*} 6 Friday
    *                                               {*} 7 Saturday
    *
    * @value       i_flg_week                       {*} 1 first
    *                                               {*} 2 second
    *                                               {*} 3 third
    *                                               {*} 4 fourth
    *                                               {*} 5 last
    *
    * @value       o_flg_recurr_pattern             {*} '0' without recurrence
    *                                               {*} 'D' daily
    *                                               {*} 'W' weekly
    *                                               {*} 'M' monthly
    *                                               {*} 'Y' yearly
    *
    * @value       o_flg_recurr_pattern             {*} 'M' month days
    *                                               {*} 'W' week days
    *
    * @value       o_flg_end_by                     {*} 'D' date
    *                                               {*} 'W' without end date
    *                                               {*} 'N' number of executions
    *                                               {*} 'L' duration
    *
    * @value       o_flg_week_day                   {*} 1 Sunday
    *                                               {*} 2 Monday
    *                                               {*} 3 Tuesday
    *                                               {*} 4 Wednesday
    *                                               {*} 5 Thursday
    *                                               {*} 6 Friday
    *                                               {*} 7 Saturday
    *
    * @value       o_flg_week                       {*} 1 first
    *                                               {*} 2 second
    *                                               {*} 3 third
    *                                               {*} 4 fourth
    *                                               {*} 5 last
    *
    * @value       o_flg_regular_interval_edit      {*} 'Y' regular interval field must be editable
    *                                               {*} 'N' regular interval field must be not editable
    *
    * @value       o_flg_daily_executions_edit      {*} 'Y' daily executions field must be editable
    *                                               {*} 'N' daily executions field must be not editable
    *
    * @value       o_flg_predef_time_sched_edit     {*} 'Y' predefined time schedules field field must be editable
    *                                               {*} 'N' predefined time schedules field field must be not editable
    *
    * @value       o_flg_exec_time_edit             {*} 'Y' execution times fields must be editable
    *                                               {*} 'N' execution times fields must be not editable
    *
    * @value       o_flg_repeat_every_edit          {*} 'Y' "repeat every" field must be editable
    *                                               {*} 'N' "repeat every" field must be not editable
    *
    * @value       o_flg_repeat_by_edit             {*} 'Y' "repeat by" field must be editable
    *                                               {*} 'N' "repeat by" field must be not editable
    *
    * @value       o_flg_start_date_edit            {*} 'Y' start date field must be editable
    *                                               {*} 'N' start date field must be not editable
    *
    * @value       o_flg_end_by_edit                {*} 'Y' "end by" field must be editable
    *                                               {*} 'N' "end by" field must be not editable
    *
    * @value       o_flg_end_after_edit             {*} 'Y' "end after" field must be editable
    *                                               {*} 'N' "end after" field must be not editable
    *
    * @value       o_flg_week_day_edit              {*} 'Y' "week day" field must be editable
    *                                               {*} 'N' "week day" field must be not editable
    *
    * @value       o_flg_week_edit                  {*} 'Y' "week" field must be editable
    *                                               {*} 'N' "week" field must be not editable
    *
    * @value       o_flg_month_day_edit             {*} 'Y' "month day" field must be editable
    *                                               {*} 'N' "month day" field must be not editable
    *
    * @value       o_flg_month_edit                 {*} 'Y' "month" field must be editable
    *                                               {*} 'N' "month" field must be not editable
    *
    * @value       o_flg_ok_avail                   {*} 'Y' ok button must be available
    *                                               {*} 'N' ok bytton must be not available
    *
    * @return      boolean                          true on success, otherwise false
    *
    * @author                                       Tiago Silva
    * @since                                        29-APR-2011
    ********************************************************************************************/
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
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * check other order recurrence option data
    *
    * @param       i_lang                           preferred language id
    * @param       i_prof                           professional structure
    * @param       i_order_recurr_plans             array of order recurrence plan ids
    * @param       i_edit_field_name                name of field edited by the user
    * @param       i_regular_interval               regular interval
    * @param       i_unit_meas_regular_interval     regular interval unit measure
    * @param       i_daily_executions               number of daily executions
    * @param       i_predef_time_sched              predefined time schedules ids
    * @param       i_exec_time_parent_option        array of execution time parent options (predefined time schedules options)
    * @param       i_exec_time_option               array of execution time options
    * @param       i_exec_time                      array of exec times
    * @param       i_exec_time_offset               array of exec time offsets
    * @param       i_unit_meas_exec_time_offset     array of exec time offsets unit measures
    * @param       i_flg_recurr_pattern             flag that indicates the recurrence pattern
    * @param       i_repeat_every                   recurrence frequency
    * @param       i_flg_repeat_by                  flag that indicates if the recurrence pattern must be repeated by month days or week days
    * @param       i_start_date                     order start date defined by the user
    * @param       i_flg_end_by                     flag that indicates which parameter must be considered to calculate the recurrence end date
    * @param       i_occurrences                    number of occurrences
    * @param       i_duration                       duration
    * @param       i_unit_meas_duration             duration unit measure
    * @param       i_end_date                       order end date
    * @param       i_flg_week_day                   array of week day options
    * @param       i_flg_week                       array of week options
    * @param       i_flg_context                    flag that indicates the application context where this function is being called
    * @param       o_regular_interval               regular interval
    * @param       o_unit_meas_regular_interval     regular interval unit measure
    * @param       o_regular_interval_desc          regular interval description
    * @param       o_daily_executions               number of daily executions
    * @param       o_predef_time_sched              predefined time schedules ids
    * @param       o_predef_time_sched_desc         predefined time schedule field description
    * @param       o_exec_times                     cursor of execution times
    * @param       o_flg_recurr_pattern             flag that indicates the recurrence pattern
    * @param       o_recurr_pattern_desc            recurrence pattern description
    * @param       o_repeat_every                   recurrence frequency
    * @param       o_unit_meas_repeat_every         recurrence frequency unit measure
    * @param       o_repeat_every_desc              recurrence frequency description
    * @param       o_flg_repeat_by                  flag that indicates if the recurrence pattern must be repeated by month days or week days
    * @param       o_repeat_by_desc                 "repeat by" field description
    * @param       o_start_date                     order start date defined by the user
    * @param       o_flg_end_by                     flag that indicates which parameter must be considered to calculate the recurrence end date
    * @param       o_end_by_desc                    "end by" field description
    * @param       o_occurrences                    number of occurrences
    * @param       o_duration                       duration
    * @param       o_unit_meas_duration             duration unit measure
    * @param       o_end_date                       order end date
    * @param       o_end_after_desc                 "end after" field description
    * @param       o_flg_week_day                   array of week day options
    * @param       o_week_day_desc                  "week day" field description
    * @param       o_flg_week                       array of week options
    * @param       o_week_desc                      "week" field description
    * @param       o_month_day                      array of month day options
    * @param       o_month                          array of month options
    * @param       o_month_desc                     "month" field description
    * @param       o_flg_regular_interval_edit      flag that indicates if regular interval field must be editable or not
    * @param       o_flg_daily_executions_edit      flag that indicates if daily executions field must be editable or not
    * @param       o_flg_predef_time_sched_edit     flag that indicates if predefined time schedules field must be editable or not
    * @param       o_flg_exec_time_edit             flag that indicates if execution times fields must be editable or not
    * @param       o_flg_repeat_every_edit          flag that indicates if "repeat every" field must be editable or not
    * @param       o_flg_repeat_by_edit             flag that indicates if "repeat by" field must be editable or not
    * @param       o_flg_start_date_edit            flag that indicates if start date field must be editable or not
    * @param       o_flg_end_by_edit                flag that indicates if "end by" field must be editable or not
    * @param       o_flg_end_after_edit             flag that indicates if "end after" field must be editable or not
    * @param       o_flg_week_day_edit              flag that indicates if "week day" field must be editable or not
    * @param       o_flg_week_edit                  flag that indicates if "week" field must be editable or not
    * @param       o_flg_month_day_edit             flag that indicates if "month day" field must editable or not
    * @param       o_flg_month_edit                 flag that indicates if "month" field must editable or not
    * @param       o_flg_ok_avail                   flag that indicates if ok button must be available or not
    * @param       o_error                          error structure for exception handling
    *
    * @value       i_flg_recurr_pattern             {*} '0' without recurrence
    *                                               {*} 'D' daily
    *                                               {*} 'W' weekly
    *                                               {*} 'M' monthly
    *                                               {*} 'Y' yearly
    *
    * @value       i_flg_recurr_pattern             {*} 'M' month days
    *                                               {*} 'W' week days
    *
    * @value       i_flg_end_by                     {*} 'D' date
    *                                               {*} 'W' without end date
    *                                               {*} 'N' number of executions
    *                                               {*} 'L' duration
    *
    * @value       i_flg_week_day                   {*} 1 Sunday
    *                                               {*} 2 Monday
    *                                               {*} 3 Tuesday
    *                                               {*} 4 Wednesday
    *                                               {*} 5 Thursday
    *                                               {*} 6 Friday
    *                                               {*} 7 Saturday
    *
    * @value       i_flg_week                       {*} 1 first
    *                                               {*} 2 second
    *                                               {*} 3 third
    *                                               {*} 4 fourth
    *                                               {*} 5 last
    *
    * @value       i_flg_context                    {*} 'S' settings context
    *                                               {*} 'P' patient context
    *
    * @value       o_flg_recurr_pattern             {*} '0' without recurrence
    *                                               {*} 'D' daily
    *                                               {*} 'W' weekly
    *                                               {*} 'M' monthly
    *                                               {*} 'Y' yearly
    *
    * @value       o_flg_recurr_pattern             {*} 'M' month days
    *                                               {*} 'W' week days
    *
    * @value       o_flg_end_by                     {*} 'D' date
    *                                               {*} 'W' without end date
    *                                               {*} 'N' number of executions
    *                                               {*} 'L' duration
    *
    * @value       o_flg_week_day                   {*} 1 Sunday
    *                                               {*} 2 Monday
    *                                               {*} 3 Tuesday
    *                                               {*} 4 Wednesday
    *                                               {*} 5 Thursday
    *                                               {*} 6 Friday
    *                                               {*} 7 Saturday
    *
    * @value       o_flg_week                       {*} 1 first
    *                                               {*} 2 second
    *                                               {*} 3 third
    *                                               {*} 4 fourth
    *                                               {*} 5 last
    *
    * @value       o_flg_regular_interval_edit      {*} 'Y' regular interval field must be editable
    *                                               {*} 'N' regular interval field must be not editable
    *
    * @value       o_flg_daily_executions_edit      {*} 'Y' daily executions field must be editable
    *                                               {*} 'N' daily executions field must be not editable
    *
    * @value       o_flg_predef_time_sched_edit     {*} 'Y' predefined time schedules field field must be editable
    *                                               {*} 'N' predefined time schedules field field must be not editable
    *
    * @value       o_flg_exec_time_edit             {*} 'Y' execution times fields must be editable
    *                                               {*} 'N' execution times fields must be not editable
    *
    * @value       o_flg_repeat_every_edit          {*} 'Y' "repeat every" field must be editable
    *                                               {*} 'N' "repeat every" field must be not editable
    *
    * @value       o_flg_repeat_by_edit             {*} 'Y' "repeat by" field must be editable
    *                                               {*} 'N' "repeat by" field must be not editable
    *
    * @value       o_flg_start_date_edit            {*} 'Y' start date field must be editable
    *                                               {*} 'N' start date field must be not editable
    *
    * @value       o_flg_end_by_edit                {*} 'Y' "end by" field must be editable
    *                                               {*} 'N' "end by" field must be not editable
    *
    * @value       o_flg_end_after_edit             {*} 'Y' "end after" field must be editable
    *                                               {*} 'N' "end after" field must be not editable
    *
    * @value       o_flg_week_day_edit              {*} 'Y' "week day" field must be editable
    *                                               {*} 'N' "week day" field must be not editable
    *
    * @value       o_flg_week_edit                  {*} 'Y' "week" field must be editable
    *                                               {*} 'N' "week" field must be not editable
    *
    * @value       o_flg_month_day_edit             {*} 'Y' "month day" field must be editable
    *                                               {*} 'N' "month day" field must be not editable
    *
    * @value       o_flg_month_edit                 {*} 'Y' "month" field must be editable
    *                                               {*} 'N' "month" field must be not editable
    *
    * @value       o_flg_ok_avail                   {*} 'Y' ok button must be available
    *                                               {*} 'N' ok bytton must be not available
    *
    * @return      boolean                          true on success, otherwise false
    *
    * @author                                       Tiago Silva
    * @since                                        29-APR-2011
    ********************************************************************************************/
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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get order recurrence plan description
    *
    * @param       i_lang                     preferred language id
    * @param       i_prof                     professional structure
    * @param       i_order_recurr_plan        order recurrence plan id
    * @param       o_error                    error structure for exception handling
    *
    * @return      varchar2                   order recurrence plan description
    *
    * @author                                 Carlos Loureiro
    * @since                                  12-MAY-2011
    ********************************************************************************************/
    FUNCTION get_order_recurr_plan_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get order recurrence instructions
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_order_plan             the order recurrence plan
    * @param       o_order_recurr_desc      order recurrence description
    * @param       o_order_recurr_option    order recurrence option id
    * @param       o_start_date             calculated order start date
    * @param       o_ocurrences             number of occurrences considered in this plan
    * @param       o_duration               duration considered in this plan
    * @param       o_unit_meas_duration     duration unit measure considered in this plan
    * @param       o_duration_desc          duration description
    * @param       o_end_date               calculated order plan end date
    * @param       o_flg_end_by_editable    flag that indicates if "executions", "duration" and "end date" fields must be editable or not
    * @param       o_order_recurr_plan      order recurrence plan id
    * @param       o_error                  error structure for exception handling
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Tiago Silva
    * @since                                14-JUN-2011
    ********************************************************************************************/
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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    FUNCTION set_order_recurr_other_option
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_order_recurr_plan    IN table_number,
        i_tbl_ds_internal_name IN table_varchar,
        i_tbl_real_val         IN table_table_varchar,
        i_value_mea            IN table_table_varchar,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************/
    /********************************************************************************************/
    /********************************************************************************************/
    -- general error descriptions
    g_error VARCHAR2(4000);

    -- log variables
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

END pk_order_recurrence_api_ux;
/
