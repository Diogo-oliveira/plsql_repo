/*-- Last Change Revision: $Rev: 1749151 $*/
/*-- Last Change by: $Author: paulo.teixeira $*/
/*-- Date of last change: $Date: 2016-07-28 08:55:42 +0100 (qui, 28 jul 2016) $*/
CREATE OR REPLACE PACKAGE ts_pn_prof_soap_button
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Julho 14, 2016 11:22:16
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "PN_PROF_SOAP_BUTTON"
    TYPE pn_prof_soap_button_tc IS TABLE OF pn_prof_soap_button%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE pn_prof_soap_button_ntt IS TABLE OF pn_prof_soap_button%ROWTYPE;
    TYPE pn_prof_soap_button_vat IS VARRAY(100) OF pn_prof_soap_button%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF pn_prof_soap_button%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF pn_prof_soap_button%ROWTYPE;
    TYPE vat IS VARRAY(100) OF pn_prof_soap_button%ROWTYPE;

    -- Column Collection based on column "ID_PROFILE_TEMPLATE"
    TYPE id_profile_template_cc IS TABLE OF pn_prof_soap_button.id_profile_template%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_USER"
    TYPE create_user_cc IS TABLE OF pn_prof_soap_button.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_TIME"
    TYPE create_time_cc IS TABLE OF pn_prof_soap_button.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_INSTITUTION"
    TYPE create_institution_cc IS TABLE OF pn_prof_soap_button.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_USER"
    TYPE update_user_cc IS TABLE OF pn_prof_soap_button.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_TIME"
    TYPE update_time_cc IS TABLE OF pn_prof_soap_button.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_INSTITUTION"
    TYPE update_institution_cc IS TABLE OF pn_prof_soap_button.update_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_CONF_BUTTON_BLOCK"
    TYPE id_conf_button_block_cc IS TABLE OF pn_prof_soap_button.id_conf_button_block%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_INSTITUTION"
    TYPE id_institution_cc IS TABLE OF pn_prof_soap_button.id_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_CATEGORY"
    TYPE id_category_cc IS TABLE OF pn_prof_soap_button.id_category%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_SOFTWARE"
    TYPE id_software_cc IS TABLE OF pn_prof_soap_button.id_software%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_CONFIG_TYPE"
    TYPE flg_config_type_cc IS TABLE OF pn_prof_soap_button.flg_config_type%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_institution_in       IN pn_prof_soap_button.id_institution%TYPE,
        id_profile_template_in  IN pn_prof_soap_button.id_profile_template%TYPE,
        id_conf_button_block_in IN pn_prof_soap_button.id_conf_button_block%TYPE,
        id_software_in          IN pn_prof_soap_button.id_software%TYPE,
        id_category_in          IN pn_prof_soap_button.id_category%TYPE,
        flg_config_type_in      IN pn_prof_soap_button.flg_config_type%TYPE,
        create_user_in          IN pn_prof_soap_button.create_user%TYPE DEFAULT NULL,
        create_time_in          IN pn_prof_soap_button.create_time%TYPE DEFAULT NULL,
        create_institution_in   IN pn_prof_soap_button.create_institution%TYPE DEFAULT NULL,
        update_user_in          IN pn_prof_soap_button.update_user%TYPE DEFAULT NULL,
        update_time_in          IN pn_prof_soap_button.update_time%TYPE DEFAULT NULL,
        update_institution_in   IN pn_prof_soap_button.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_institution_in       IN pn_prof_soap_button.id_institution%TYPE,
        id_profile_template_in  IN pn_prof_soap_button.id_profile_template%TYPE,
        id_conf_button_block_in IN pn_prof_soap_button.id_conf_button_block%TYPE,
        id_software_in          IN pn_prof_soap_button.id_software%TYPE,
        id_category_in          IN pn_prof_soap_button.id_category%TYPE,
        flg_config_type_in      IN pn_prof_soap_button.flg_config_type%TYPE,
        create_user_in          IN pn_prof_soap_button.create_user%TYPE DEFAULT NULL,
        create_time_in          IN pn_prof_soap_button.create_time%TYPE DEFAULT NULL,
        create_institution_in   IN pn_prof_soap_button.create_institution%TYPE DEFAULT NULL,
        update_user_in          IN pn_prof_soap_button.update_user%TYPE DEFAULT NULL,
        update_time_in          IN pn_prof_soap_button.update_time%TYPE DEFAULT NULL,
        update_institution_in   IN pn_prof_soap_button.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    PROCEDURE ins
    (
        rec_in          IN pn_prof_soap_button%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN pn_prof_soap_button%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN pn_prof_soap_button_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN pn_prof_soap_button_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        id_institution_in       IN pn_prof_soap_button.id_institution%TYPE,
        id_profile_template_in  IN pn_prof_soap_button.id_profile_template%TYPE,
        id_conf_button_block_in IN pn_prof_soap_button.id_conf_button_block%TYPE,
        id_software_in          IN pn_prof_soap_button.id_software%TYPE,
        id_category_in          IN pn_prof_soap_button.id_category%TYPE,
        flg_config_type_in      IN pn_prof_soap_button.flg_config_type%TYPE,
        create_user_in          IN pn_prof_soap_button.create_user%TYPE DEFAULT NULL,
        create_user_nin         IN BOOLEAN := TRUE,
        create_time_in          IN pn_prof_soap_button.create_time%TYPE DEFAULT NULL,
        create_time_nin         IN BOOLEAN := TRUE,
        create_institution_in   IN pn_prof_soap_button.create_institution%TYPE DEFAULT NULL,
        create_institution_nin  IN BOOLEAN := TRUE,
        update_user_in          IN pn_prof_soap_button.update_user%TYPE DEFAULT NULL,
        update_user_nin         IN BOOLEAN := TRUE,
        update_time_in          IN pn_prof_soap_button.update_time%TYPE DEFAULT NULL,
        update_time_nin         IN BOOLEAN := TRUE,
        update_institution_in   IN pn_prof_soap_button.update_institution%TYPE DEFAULT NULL,
        update_institution_nin  IN BOOLEAN := TRUE,
        handle_error_in         IN BOOLEAN := TRUE,
        rows_out                IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_institution_in       IN pn_prof_soap_button.id_institution%TYPE,
        id_profile_template_in  IN pn_prof_soap_button.id_profile_template%TYPE,
        id_conf_button_block_in IN pn_prof_soap_button.id_conf_button_block%TYPE,
        id_software_in          IN pn_prof_soap_button.id_software%TYPE,
        id_category_in          IN pn_prof_soap_button.id_category%TYPE,
        flg_config_type_in      IN pn_prof_soap_button.flg_config_type%TYPE,
        create_user_in          IN pn_prof_soap_button.create_user%TYPE DEFAULT NULL,
        create_user_nin         IN BOOLEAN := TRUE,
        create_time_in          IN pn_prof_soap_button.create_time%TYPE DEFAULT NULL,
        create_time_nin         IN BOOLEAN := TRUE,
        create_institution_in   IN pn_prof_soap_button.create_institution%TYPE DEFAULT NULL,
        create_institution_nin  IN BOOLEAN := TRUE,
        update_user_in          IN pn_prof_soap_button.update_user%TYPE DEFAULT NULL,
        update_user_nin         IN BOOLEAN := TRUE,
        update_time_in          IN pn_prof_soap_button.update_time%TYPE DEFAULT NULL,
        update_time_nin         IN BOOLEAN := TRUE,
        update_institution_in   IN pn_prof_soap_button.update_institution%TYPE DEFAULT NULL,
        update_institution_nin  IN BOOLEAN := TRUE,
        handle_error_in         IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        create_user_in         IN pn_prof_soap_button.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN pn_prof_soap_button.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN pn_prof_soap_button.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN pn_prof_soap_button.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN pn_prof_soap_button.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN pn_prof_soap_button.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        where_in               VARCHAR2,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    PROCEDURE upd
    (
        create_user_in         IN pn_prof_soap_button.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN pn_prof_soap_button.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN pn_prof_soap_button.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN pn_prof_soap_button.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN pn_prof_soap_button.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN pn_prof_soap_button.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        where_in               VARCHAR2,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_institution_in       IN pn_prof_soap_button.id_institution%TYPE,
        id_profile_template_in  IN pn_prof_soap_button.id_profile_template%TYPE,
        id_conf_button_block_in IN pn_prof_soap_button.id_conf_button_block%TYPE,
        id_software_in          IN pn_prof_soap_button.id_software%TYPE,
        id_category_in          IN pn_prof_soap_button.id_category%TYPE,
        flg_config_type_in      IN pn_prof_soap_button.flg_config_type%TYPE,
        create_user_in          IN pn_prof_soap_button.create_user%TYPE DEFAULT NULL,
        create_time_in          IN pn_prof_soap_button.create_time%TYPE DEFAULT NULL,
        create_institution_in   IN pn_prof_soap_button.create_institution%TYPE DEFAULT NULL,
        update_user_in          IN pn_prof_soap_button.update_user%TYPE DEFAULT NULL,
        update_time_in          IN pn_prof_soap_button.update_time%TYPE DEFAULT NULL,
        update_institution_in   IN pn_prof_soap_button.update_institution%TYPE DEFAULT NULL,
        handle_error_in         IN BOOLEAN := TRUE,
        rows_out                OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_institution_in       IN pn_prof_soap_button.id_institution%TYPE,
        id_profile_template_in  IN pn_prof_soap_button.id_profile_template%TYPE,
        id_conf_button_block_in IN pn_prof_soap_button.id_conf_button_block%TYPE,
        id_software_in          IN pn_prof_soap_button.id_software%TYPE,
        id_category_in          IN pn_prof_soap_button.id_category%TYPE,
        flg_config_type_in      IN pn_prof_soap_button.flg_config_type%TYPE,
        create_user_in          IN pn_prof_soap_button.create_user%TYPE DEFAULT NULL,
        create_time_in          IN pn_prof_soap_button.create_time%TYPE DEFAULT NULL,
        create_institution_in   IN pn_prof_soap_button.create_institution%TYPE DEFAULT NULL,
        update_user_in          IN pn_prof_soap_button.update_user%TYPE DEFAULT NULL,
        update_time_in          IN pn_prof_soap_button.update_time%TYPE DEFAULT NULL,
        update_institution_in   IN pn_prof_soap_button.update_institution%TYPE DEFAULT NULL,
        handle_error_in         IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN pn_prof_soap_button%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN pn_prof_soap_button%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN pn_prof_soap_button_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN pn_prof_soap_button_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Use Native Dynamic SQL increment a single NUMBER column
    -- for all rows specified by the dynamic WHERE clause
    PROCEDURE increment_onecol
    (
        colname_in         IN all_tab_columns.column_name%TYPE,
        where_in           IN VARCHAR2 := NULL,
        increment_value_in IN NUMBER DEFAULT 1,
        handle_error_in    IN BOOLEAN := TRUE,
        rows_out           OUT table_varchar
    );

    PROCEDURE increment_onecol
    (
        colname_in         IN all_tab_columns.column_name%TYPE,
        where_in           IN VARCHAR2 := NULL,
        increment_value_in IN NUMBER DEFAULT 1,
        handle_error_in    IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_institution_in       IN pn_prof_soap_button.id_institution%TYPE,
        id_profile_template_in  IN pn_prof_soap_button.id_profile_template%TYPE,
        id_conf_button_block_in IN pn_prof_soap_button.id_conf_button_block%TYPE,
        id_software_in          IN pn_prof_soap_button.id_software%TYPE,
        id_category_in          IN pn_prof_soap_button.id_category%TYPE,
        flg_config_type_in      IN pn_prof_soap_button.flg_config_type%TYPE,
        handle_error_in         IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_institution_in       IN pn_prof_soap_button.id_institution%TYPE,
        id_profile_template_in  IN pn_prof_soap_button.id_profile_template%TYPE,
        id_conf_button_block_in IN pn_prof_soap_button.id_conf_button_block%TYPE,
        id_software_in          IN pn_prof_soap_button.id_software%TYPE,
        id_category_in          IN pn_prof_soap_button.id_category%TYPE,
        flg_config_type_in      IN pn_prof_soap_button.flg_config_type%TYPE,
        handle_error_in         IN BOOLEAN := TRUE,
        rows_out                OUT table_varchar
    );

    -- Delete all rows for primary key column ID_INSTITUTION
    PROCEDURE del_id_institution
    (
        id_institution_in IN pn_prof_soap_button.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_INSTITUTION
    PROCEDURE del_id_institution
    (
        id_institution_in IN pn_prof_soap_button.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows for primary key column ID_PROFILE_TEMPLATE
    PROCEDURE del_id_profile_template
    (
        id_profile_template_in IN pn_prof_soap_button.id_profile_template%TYPE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_PROFILE_TEMPLATE
    PROCEDURE del_id_profile_template
    (
        id_profile_template_in IN pn_prof_soap_button.id_profile_template%TYPE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               OUT table_varchar
    );

    -- Delete all rows for primary key column ID_CONF_BUTTON_BLOCK
    PROCEDURE del_id_conf_button_block
    (
        id_conf_button_block_in IN pn_prof_soap_button.id_conf_button_block%TYPE,
        handle_error_in         IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_CONF_BUTTON_BLOCK
    PROCEDURE del_id_conf_button_block
    (
        id_conf_button_block_in IN pn_prof_soap_button.id_conf_button_block%TYPE,
        handle_error_in         IN BOOLEAN := TRUE,
        rows_out                OUT table_varchar
    );

    -- Delete all rows for primary key column ID_SOFTWARE
    PROCEDURE del_id_software
    (
        id_software_in  IN pn_prof_soap_button.id_software%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_SOFTWARE
    PROCEDURE del_id_software
    (
        id_software_in  IN pn_prof_soap_button.id_software%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for primary key column ID_CATEGORY
    PROCEDURE del_id_category
    (
        id_category_in  IN pn_prof_soap_button.id_category%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_CATEGORY
    PROCEDURE del_id_category
    (
        id_category_in  IN pn_prof_soap_button.id_category%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for primary key column FLG_CONFIG_TYPE
    PROCEDURE del_flg_config_type
    (
        flg_config_type_in IN pn_prof_soap_button.flg_config_type%TYPE,
        handle_error_in    IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column FLG_CONFIG_TYPE
    PROCEDURE del_flg_config_type
    (
        flg_config_type_in IN pn_prof_soap_button.flg_config_type%TYPE,
        handle_error_in    IN BOOLEAN := TRUE,
        rows_out           OUT table_varchar
    );

    -- Delete all rows for this PPSB_PROFILE_TEMPLATE_FK foreign key value
    PROCEDURE del_ppsb_profile_template_fk
    (
        id_profile_template_in IN pn_prof_soap_button.id_profile_template%TYPE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PPSB_PROFILE_TEMPLATE_FK foreign key value
    PROCEDURE del_ppsb_profile_template_fk
    (
        id_profile_template_in IN pn_prof_soap_button.id_profile_template%TYPE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               OUT table_varchar
    );

    -- Delete all rows for this PSBB_CBB_FK foreign key value
    PROCEDURE del_psbb_cbb_fk
    (
        id_conf_button_block_in IN pn_prof_soap_button.id_conf_button_block%TYPE,
        handle_error_in         IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PSBB_CBB_FK foreign key value
    PROCEDURE del_psbb_cbb_fk
    (
        id_conf_button_block_in IN pn_prof_soap_button.id_conf_button_block%TYPE,
        handle_error_in         IN BOOLEAN := TRUE,
        rows_out                OUT table_varchar
    );

    -- Delete all rows for this PSBB_INST_FK foreign key value
    PROCEDURE del_psbb_inst_fk
    (
        id_institution_in IN pn_prof_soap_button.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PSBB_INST_FK foreign key value
    PROCEDURE del_psbb_inst_fk
    (
        id_institution_in IN pn_prof_soap_button.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows specified by dynamic WHERE clause
    PROCEDURE del_by
    (
        where_clause_in IN VARCHAR2,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows specified by dynamic WHERE clause
    PROCEDURE del_by
    (
        where_clause_in IN VARCHAR2,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows where the specified VARCHAR2 column has
    -- a value that matches the specfified value.
    PROCEDURE del_by_col
    (
        colname_in      IN VARCHAR2,
        colvalue_in     IN VARCHAR2,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows where the specified VARCHAR2 column has
    -- a value that matches the specfified value.
    PROCEDURE del_by_col
    (
        colname_in      IN VARCHAR2,
        colvalue_in     IN VARCHAR2,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows where the specified DATE column has
    -- a value that matches the specfified value.
    PROCEDURE del_by_col
    (
        colname_in      IN VARCHAR2,
        colvalue_in     IN DATE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows where the specified DATE column has
    -- a value that matches the specfified value.
    PROCEDURE del_by_col
    (
        colname_in      IN VARCHAR2,
        colvalue_in     IN DATE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows where the specified TIMESTAMP column has
    -- a value that matches the specfified value.
    PROCEDURE del_by_col
    (
        colname_in      IN VARCHAR2,
        colvalue_in     IN TIMESTAMP WITH LOCAL TIME ZONE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows where the specified TIMESTAMP column has
    -- a value that matches the specfified value.
    PROCEDURE del_by_col
    (
        colname_in      IN VARCHAR2,
        colvalue_in     IN TIMESTAMP WITH LOCAL TIME ZONE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows where the specified NUMBER column has
    -- a value that matches the specfified value.
    PROCEDURE del_by_col
    (
        colname_in      IN VARCHAR2,
        colvalue_in     IN NUMBER,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows where the specified NUMBER column has
    -- a value that matches the specfified value.
    PROCEDURE del_by_col
    (
        colname_in      IN VARCHAR2,
        colvalue_in     IN NUMBER,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Initialize a record with default values for columns in the table.
    PROCEDURE initrec(pn_prof_soap_button_inout IN OUT pn_prof_soap_button%ROWTYPE);

    FUNCTION initrec RETURN pn_prof_soap_button%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN pn_prof_soap_button_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN pn_prof_soap_button_tc;

END ts_pn_prof_soap_button;
/
