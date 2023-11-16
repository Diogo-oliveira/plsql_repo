/*-- Last Change Revision: $Rev: 2028630 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:00 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ea_logic_bmng IS

    -- Author  : LUIS.MAIA
    -- Created : 28-07-2009 23:45:46
    -- Purpose : Package that should contain all easy access logic for Bed management functionality

    ----------------------------------------   FUNCTIONS   ----------------------------------------------

    /*******************************************************************************************************************************************
    * Name:                           SET_BMNG_BED
    * Description:                    Function that updates bed action information in the BED Management Easy Access table (BMNG_BED_EA)
    * 
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_EVENT_TYPE             Type of event (UPDATE, INSERT, etc)
    * @param I_ROWIDS                 List of ROWIDs belonging to the changed records.
    * @param I_LIST_COLUMNS           List of columns that were changed
    * @param I_SOURCE_TABLE_NAME      Name of the table that was changed.
    * @param I_DG_TABLE_NAME          Name of the Data Governance table.
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_EVENT_TYPE             {*} t_data_gov_mnt.g_event_insert {*} t_data_gov_mnt.g_event_update {*} t_data_gov_mnt.g_event_delete
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/07/29
    *******************************************************************************************************************************************/
    PROCEDURE set_bmng_bed
    (
        i_lang              IN LANGUAGE.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );
    /**
    * Process insert/update events on EPIS_DIET_REQ into TASK_TIMELINE_EA.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_event_type   event type
    * @param i_rowids       changed records rowids list
    * @param i_src_table    source table name
    * @param i_list_columns changed column names list
    * @param i_dg_table     easy access table name
    *
    * @author               paulo teixeira
    * @version               2.6.3
    * @since                2013/04/30
    */
    PROCEDURE set_bmng_department_ea
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_event_type   IN VARCHAR2,
        i_rowids       IN table_varchar,
        i_src_table    IN VARCHAR2,
        i_list_columns IN table_varchar,
        i_dg_table     IN VARCHAR2
    );
    
        PROCEDURE set_bmng_department_bed_ea
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_event_type   IN VARCHAR2,
        i_rowids       IN table_varchar,
        i_src_table    IN VARCHAR2,
        i_list_columns IN table_varchar,
        i_dg_table     IN VARCHAR2
    );
    ---------------------------------------- GLOBAL VALUES ----------------------------------------------

    g_bed_status_n      CONSTANT VARCHAR2(1) := 'N'; --Normal
    g_bed_ocup_status_v CONSTANT VARCHAR2(1) := 'V'; --Vago

    g_sysdate_tstz TIMESTAMP
        WITH LOCAL TIME ZONE;

    /* Package name */
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);

    /* Error tracking */
    g_error VARCHAR2(4000);

    /* Invalid event type */
    g_excp_invalid_event_type EXCEPTION;

END pk_ea_logic_bmng;
/
