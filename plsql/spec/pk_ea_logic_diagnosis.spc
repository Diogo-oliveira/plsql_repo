/*-- Last Change Revision: $Rev: 1632557 $*/
/*-- Last Change by: $Author: sergio.dias $*/
/*-- Date of last change: $Date: 2014-09-11 18:48:36 +0100 (qui, 11 set 2014) $*/
CREATE OR REPLACE PACKAGE pk_ea_logic_diagnosis IS

    g_error VARCHAR2(200 CHAR);
    /* Package name */
    g_package_owner VARCHAR2(50 CHAR);
    g_package_name  VARCHAR2(50 CHAR);

    -- Record status
    g_flg_active_y VARCHAR2(1 CHAR) := 'Y';
    g_flg_active_n VARCHAR2(1 CHAR) := 'N';

    -- Easy access table names
    g_diagnosis_ea           VARCHAR2(40 CHAR) := 'DIAGNOSIS_EA';
    g_diagnosis_conf_ea      VARCHAR2(40 CHAR) := 'DIAGNOSIS_CONF_EA';
    g_diagnosis_relations_ea VARCHAR2(40 CHAR) := 'DIAGNOSIS_RELATIONS_EA';

    -- Past history content type
    g_past_hist_diag_type CONSTANT diagnosis_ea.flg_msi_concept_term%TYPE := 'H';

    --Easy acess record types
    TYPE r_diag_ea_terminology IS RECORD(
        id_terminology  terminology.id_terminology%TYPE,
        flg_terminology diagnosis_ea.flg_terminology%TYPE);

    TYPE t_diag_ea_terminologies IS TABLE OF r_diag_ea_terminology;

    /********************************************************************************************
    * Get all distinct diagnosis_ea terminologies.
    * Excludes id_inst = 0 and flg_msi_concept_term = H; -- i.e. Excludes Past History Terminologies
    *
    * @param i_institution        Institution id
    *
    * @author                     Alexandre Santos
    * @version                    2.6.2.1
    * @since                      05-Jun-2012
    *
    **********************************************************************************************/
    FUNCTION tf_diag_ea_terminologies(i_institution IN institution.id_institution%TYPE) RETURN t_diag_ea_terminologies
        PIPELINED;

    /********************************************************************************************
    * Inserts or Updates records in DIAGNOSIS_EA table.
    *
    * @param i_r_diagnosis_ea     DIAGNOSIS_EA row
    *
    * @author                     José Brito
    * @version                    2.6.2
    * @since                      29-Feb-2012
    *
    **********************************************************************************************/
    PROCEDURE ins_diagnosis_ea(i_r_diagnosis_ea IN pk_api_pfh_diagnosis_in.g_rec_diagnosis_ea%TYPE);

    /********************************************************************************************
    * Inserts or Updates MSI_CONCEPT_TERM related fields in the DIAGNOSIS_EA table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author                     José Brito
    * @version                    2.6.2
    * @since                      29-Feb-2012
    *
    **********************************************************************************************/
    PROCEDURE set_msi_concept_term
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /********************************************************************************************
    * Inserts or Updates msi_cncpt_vers_attrib related fields in the DIAGNOSIS_EA table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author                     José Brito
    * @version                    2.6.2
    * @since                      29-Feb-2012
    *
    **********************************************************************************************/
    PROCEDURE set_msi_cncpt_vers_attrib
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /********************************************************************************************
    * Inserts or Updates MSI_CONCEPT_RELATION related fields in the DIAGNOSIS_RELATIONS_EA table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author                     José Brito
    * @version                    2.6.2
    * @since                      20-Mar-2012
    *
    **********************************************************************************************/
    PROCEDURE set_msi_concept_relation
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /********************************************************************************************
    * Inserts or Updates records in DIAGNOSIS_RELATIONS_EA table.
    *
    * @param i_r_diagnosis_rel_ea     DIAGNOSIS_RELATIONS_EA row
    *
    * @author                         José Brito
    * @version                        2.6.2
    * @since                          16-Mar-2012
    *
    **********************************************************************************************/
    PROCEDURE ins_diagnosis_relations_ea(i_r_diagnosis_rel_ea IN alert_core_func.pk_api_diagnosis_func.g_rec_diagnosis_rel_ea);

    /**
    * Updates Diagnosis information in the Task Timeline Easy Access table (task_timeline_ea)
    * 
    * @param i_lang                   Language
    * @param i_prof                   Professional
    * @param i_event_type             Type of event (UPDATE, INSERT, etc)
    * @param i_rowids                 List of ROWIDs belonging to the changed records.
    * @param i_source_table_name      Name of the table that was changed.
    * @param i_list_columns           List of columns that were changed
    * @param i_dg_table_name          Name of the Data Governance table.
    * 
    * @value i_lang                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value i_event_type             {*} t_data_gov_mnt.g_event_insert {*} t_data_gov_mnt.g_event_update {*} t_data_gov_mnt.g_event_delete
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    *
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         António Neto
    * @version                        2.6.2
    * @since                          22-Mar-2012
    */
    PROCEDURE set_task_timeline_diag
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /**
    * Updates Diagnosis Notes information in the Task Timeline Easy Access table (task_timeline_ea)
    * 
    * @param i_lang                   Language
    * @param i_prof                   Professional
    * @param i_event_type             Type of event (UPDATE, INSERT, etc)
    * @param i_rowids                 List of ROWIDs belonging to the changed records.
    * @param i_source_table_name      Name of the table that was changed.
    * @param i_list_columns           List of columns that were changed
    * @param i_dg_table_name          Name of the Data Governance table.
    * 
    * @value i_lang                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value i_event_type             {*} t_data_gov_mnt.g_event_insert {*} t_data_gov_mnt.g_event_update {*} t_data_gov_mnt.g_event_delete
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    *
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         António Neto
    * @version                        2.6.2
    * @since                          26-Mar-2012
    */
    PROCEDURE set_task_timeline_diag_notes
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /********************************************************************************************
    * Rebuils content of DIAGNOSIS_EA
    *
    * @param o_error                   Error message
    * 
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           10-Apr-2012
    *
    **********************************************************************************************/
    FUNCTION rebuild_diagnosis_ea
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Rebuils content of DIAGNOSIS_RELATIONS_EA
    *
    * @param o_error                   Error message
    * 
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           10-Apr-2012
    *
    **********************************************************************************************/
    FUNCTION rebuild_diagnosis_relations_ea(o_error OUT t_error_out) RETURN BOOLEAN;

    /********************************************************************************************
    * Rebuils content of DIAGNOSIS_EA
    *
    * @param i_institution             Institution id
    * @param i_software                Software id
    * @param i_commit                  Is to commit the transaction?
    *
    * @author                          Alexandre Santos
    * @version                         2.6.3
    * @since                           13-Aug-2013
    *
    **********************************************************************************************/
    PROCEDURE rebuild_diagnosis_ea
    (
        i_institution  IN institution.id_institution%TYPE,
        i_tbl_software IN table_number,
        i_commit       IN BOOLEAN DEFAULT TRUE
    );
END pk_ea_logic_diagnosis;
/
