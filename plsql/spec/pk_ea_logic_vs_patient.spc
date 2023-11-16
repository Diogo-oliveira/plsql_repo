/*-- Last Change Revision: $Rev: 2028656 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:09 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ea_logic_vs_patient IS

    --
    -- PUBLIC CONSTANTS
    -- 

    -- Default number of records to process between commits
    c_def_commit_steps PLS_INTEGER := 1000;

    --
    -- PUBLIC FUNCTIONS
    -- 

    /**********************************************************************************************
    * Populates Vital Signs by Patient Easy Access table
    *
    * @param        i_lang                   Language id
    * @param        i_patient                Patient id
    * @param        i_episode                Episode id
    * @value        i_schedule               Schedule id (not used)
    * @param        i_external_request       External request id (not used)
    * @param        i_institution            Institution id (not used)
    * @param        i_start_dt               Date from which start processing records
    * @param        i_end_dt                 Date by which to end processing records
    * @param        i_validate_table         If it is necessary to validate the data
    * @param        i_output_invalid_records If it is necessary to save invalid records
    * @param        i_recreate_table         If it is necessary to recreate the entire EA table
    * @param        i_commit_step            Number of records to process between commits
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Paulo Fonseca
    * @version      2.5.1
    * @since        27-Jul-2010
    **********************************************************************************************/
    FUNCTION admin
    (
        i_lang        IN language.id_language%TYPE,
        i_patient     IN vital_sign_read.id_patient%TYPE DEFAULT NULL,
        i_commit_step IN PLS_INTEGER DEFAULT c_def_commit_steps,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Updates Vital Signs Easy Access table
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_event_type             Event type (UPDATE, INSERT or DELETE)
    * @param        i_rowids                 List of changed records ROWIDs
    * @param        i_list_columns           List of changed columns 
    * @param        i_source_table_name      Changed table name
    * @param        i_dg_table_name          Data Governance table name
    *
    * @author       Paulo Fonseca
    * @version      2.5.1
    * @since        26-Jul-2010
    **********************************************************************************************/
    PROCEDURE process_event
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    );

END pk_ea_logic_vs_patient;
/
