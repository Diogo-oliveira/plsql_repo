/*-- Last Change Revision: $Rev: 2028583 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:40 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_cpoe_rp IS

    -- Computerized Prescription Order Entry (CPOE) REPORTS API database package

    /********************************************************************************************
    * get a patient's prescription tasks report
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_patient                 internal id of the patient 
    * @param       i_episode                 internal id of the episode 
    * @param       i_process                 internal id of the cpoe process 
    * @param       o_cpoe_info               cursor containing information about prescription information
    * @param       o_cpoe_task               cursor containing information about prescription's tasks 
    * @param       o_error                   error message
    *
    * @value       i_process                 {*} <ID>   cursors will have given process information
    *                                        {*} <NULL> cursors will have last/current process information 
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/12/04
    ********************************************************************************************/
    FUNCTION get_cpoe_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_process       IN cpoe_process.id_cpoe_process%TYPE,
        i_task_ids      IN table_number,
        i_task_type_ids IN table_number,
        i_dt_start      IN VARCHAR2,
        i_dt_end        IN VARCHAR2,
        o_cpoe_info     OUT pk_types.cursor_type,
        o_cpoe_task     OUT pk_types.cursor_type,
        o_execution     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_professional_br_report
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_prof IN professional.id_professional%TYPE,
        o_prof    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

END pk_cpoe_rp;
/
