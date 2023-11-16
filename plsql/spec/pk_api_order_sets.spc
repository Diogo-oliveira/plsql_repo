/*-- Last Change Revision: $Rev: 1531686 $*/
/*-- Last Change by: $Author: tiago.silva $*/
/*-- Date of last change: $Date: 2013-12-03 14:38:19 +0000 (ter, 03 dez 2013) $*/

CREATE OR REPLACE PACKAGE pk_api_order_sets IS

    -- Author  : Carlos Loureiro
    -- Purpose : API for order sets

    /********************************************************************************************
    * Returns the order set title of an order set task
    *
    * @param    I_LANG            Preferred language ID
    * @param    I_PROF            Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET    Order set ID
    *
    * @return   VARCHAR2          Order set title
    *
    * @author   Tiago Silva
    * @since    2010/06/30
    ********************************************************************************************/
    FUNCTION get_order_set_title
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN order_set_process_task.id_request%TYPE,
        i_task_type    IN order_set_process_task.id_task_type%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * updates diet references in all order sets that were using a diet that is about to be updated
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional structure
    * @param       i_diet_old                diet that is about to be updated
    * @param       i_diet_new                final diet version
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2009/07/16
    ********************************************************************************************/
    FUNCTION set_diet_references
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_diet_old IN order_set_task_link.id_task_link%TYPE,
        i_diet_new IN order_set_task_link.id_task_link%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * updates diet references for the order set process that is handling the diet
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional structure
    * @param       i_id_epis_diet_old        patient's diet that is about to be updated
    * @param       i_id_epis_diet_new        final diet version to be associated to the patient
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2009/07/23
    ********************************************************************************************/
    FUNCTION set_diet_process_references
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_epis_diet_old IN order_set_process_task.id_request%TYPE,
        i_id_epis_diet_new IN order_set_process_task.id_request%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Copy or duplicate order set
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    object (id of professional, id of institution, id of software)
    * @param       i_target_id_institution   target institution id
    * @param       i_id_order set            source order set id
    * @param       o_order_set               new order set id
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Tiago Silva
    * @version                               1.0
    * @since                                 2009/07/17
    ********************************************************************************************/
    FUNCTION copy_order_set
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_order_set          IN order_set.id_order_set%TYPE,
        o_order_set             OUT order_set.id_order_set%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel order set / mark as deleted
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    object (id of professional, id of institution, id of software)
    * @param       i_id_order_set            order set id to cancel
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Tiago Silva
    * @version                               1.0
    * @since                                 2009/07/17
    ********************************************************************************************/
    FUNCTION cancel_order_set
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_order_set IN order_set.id_order_set%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * clear particular order set processes or clear all order sets processes related with
    * a list of patients or order sets
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_patients                patients array
    * @param       i_order_sets              order sets array    
    * @param       i_order_set_processes     order set processes array         
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    *   
    * @author                                Tiago Silva
    * @since                                 2010/11/02
    ********************************************************************************************/
    FUNCTION clear_order_set_processes
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patients            IN table_number DEFAULT NULL,
        i_order_sets          IN table_number DEFAULT NULL,
        i_order_set_processes IN table_number DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * delete a list of order sets and its processes
    *
    * @param       i_lang         preferred language id for this professional
    * @param       i_prof         professional id structure
    * @param       i_order_sets   order set IDs
    * @param       o_error        error message
    *        
    * @return      boolean        true on success, otherwise false    
    *   
    * @author                     Tiago Silva
    * @since                      2010/11/02
    ********************************************************************************************/
    FUNCTION delete_order_sets
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_order_sets IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * update new task reference in all order sets that are using the old reference
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional structure
    * @param       i_task_type               task type id
    * @param       i_task_ref_old            old task reference (the one that should be updated)
    * @param       i_task_ref_new            new task reference
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @since                                 19-SEP-2011
    ********************************************************************************************/
    FUNCTION update_task_reference
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_type    IN task_type.id_task_type%TYPE,
        i_task_ref_old IN order_set_task_link.id_task_link%TYPE,
        i_task_ref_new IN order_set_task_link.id_task_link%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * update new task process reference in all order set processes that are using the old reference
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional structure
    * @param       i_task_type               task type id
    * @param       i_task_ref_old            old task reference (the one that should be updated)
    * @param       i_task_ref_new            new task reference
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @since                                 19-SEP-2011
    ********************************************************************************************/
    FUNCTION update_task_proc_reference
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_type    IN task_type.id_task_type%TYPE,
        i_task_ref_old IN order_set_task_link.id_task_link%TYPE,
        i_task_ref_new IN order_set_task_link.id_task_link%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * migrate labs and exams tasks to modular workflow task architecture
    *
    * @param       i_instit   institution ID
    *
    * @author                 Tiago Silva
    * @since                  27-NOV-2013
    ********************************************************************************************/
    PROCEDURE migrate_labs_and_exams(i_instit IN institution.id_institution%TYPE);

    /********************************************************************************************/
    /********************************************************************************************/
    /********************************************************************************************/

    -- default values
    g_duplicate_flag CONSTANT VARCHAR2(1) := 'Y';

    -- general declarations
    g_error VARCHAR2(4000);

    -- log variables
    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);

END pk_api_order_sets;
/
