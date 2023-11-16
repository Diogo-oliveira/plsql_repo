/*-- Last Change Revision: $Rev: 1528861 $*/
/*-- Last Change by: $Author: ana.monteiro $*/
/*-- Date of last change: $Date: 2013-11-27 10:48:36 +0000 (qua, 27 nov 2013) $*/
CREATE OR REPLACE PACKAGE ts_ref_orig_data
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: October 28, 2013 10:48:2
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "REF_ORIG_DATA"
    TYPE ref_orig_data_tc IS TABLE OF ref_orig_data%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ref_orig_data_ntt IS TABLE OF ref_orig_data%ROWTYPE;
    TYPE ref_orig_data_vat IS VARRAY(100) OF ref_orig_data%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF ref_orig_data%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF ref_orig_data%ROWTYPE;
    TYPE vat IS VARRAY(100) OF ref_orig_data%ROWTYPE;

    -- Column Collection based on column "ID_EXTERNAL_REQUEST"
    TYPE id_external_request_cc IS TABLE OF ref_orig_data.id_external_request%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_PROFESSIONAL"
    TYPE id_professional_cc IS TABLE OF ref_orig_data.id_professional%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "INSTITUTION_NAME"
    TYPE institution_name_cc IS TABLE OF ref_orig_data.institution_name%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_USER"
    TYPE create_user_cc IS TABLE OF ref_orig_data.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_TIME"
    TYPE create_time_cc IS TABLE OF ref_orig_data.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_INSTITUTION"
    TYPE create_institution_cc IS TABLE OF ref_orig_data.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_USER"
    TYPE update_user_cc IS TABLE OF ref_orig_data.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_TIME"
    TYPE update_time_cc IS TABLE OF ref_orig_data.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_INSTITUTION"
    TYPE update_institution_cc IS TABLE OF ref_orig_data.update_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_CREATE"
    TYPE dt_create_cc IS TABLE OF ref_orig_data.dt_create%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_external_request_in IN ref_orig_data.id_external_request%TYPE,
        id_professional_in     IN ref_orig_data.id_professional%TYPE DEFAULT NULL,
        institution_name_in    IN ref_orig_data.institution_name%TYPE DEFAULT NULL,
        create_user_in         IN ref_orig_data.create_user%TYPE DEFAULT NULL,
        create_time_in         IN ref_orig_data.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN ref_orig_data.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN ref_orig_data.update_user%TYPE DEFAULT NULL,
        update_time_in         IN ref_orig_data.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN ref_orig_data.update_institution%TYPE DEFAULT NULL,
        dt_create_in           IN ref_orig_data.dt_create%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_external_request_in IN ref_orig_data.id_external_request%TYPE,
        id_professional_in     IN ref_orig_data.id_professional%TYPE DEFAULT NULL,
        institution_name_in    IN ref_orig_data.institution_name%TYPE DEFAULT NULL,
        create_user_in         IN ref_orig_data.create_user%TYPE DEFAULT NULL,
        create_time_in         IN ref_orig_data.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN ref_orig_data.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN ref_orig_data.update_user%TYPE DEFAULT NULL,
        update_time_in         IN ref_orig_data.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN ref_orig_data.update_institution%TYPE DEFAULT NULL,
        dt_create_in           IN ref_orig_data.dt_create%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    PROCEDURE ins
    (
        rec_in          IN ref_orig_data%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN ref_orig_data%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN ref_orig_data_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN ref_orig_data_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        id_external_request_in IN ref_orig_data.id_external_request%TYPE,
        id_professional_in     IN ref_orig_data.id_professional%TYPE DEFAULT NULL,
        id_professional_nin    IN BOOLEAN := TRUE,
        institution_name_in    IN ref_orig_data.institution_name%TYPE DEFAULT NULL,
        institution_name_nin   IN BOOLEAN := TRUE,
        create_user_in         IN ref_orig_data.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN ref_orig_data.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN ref_orig_data.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN ref_orig_data.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN ref_orig_data.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN ref_orig_data.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        dt_create_in           IN ref_orig_data.dt_create%TYPE DEFAULT NULL,
        dt_create_nin          IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_external_request_in IN ref_orig_data.id_external_request%TYPE,
        id_professional_in     IN ref_orig_data.id_professional%TYPE DEFAULT NULL,
        id_professional_nin    IN BOOLEAN := TRUE,
        institution_name_in    IN ref_orig_data.institution_name%TYPE DEFAULT NULL,
        institution_name_nin   IN BOOLEAN := TRUE,
        create_user_in         IN ref_orig_data.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN ref_orig_data.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN ref_orig_data.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN ref_orig_data.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN ref_orig_data.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN ref_orig_data.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        dt_create_in           IN ref_orig_data.dt_create%TYPE DEFAULT NULL,
        dt_create_nin          IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        id_professional_in     IN ref_orig_data.id_professional%TYPE DEFAULT NULL,
        id_professional_nin    IN BOOLEAN := TRUE,
        institution_name_in    IN ref_orig_data.institution_name%TYPE DEFAULT NULL,
        institution_name_nin   IN BOOLEAN := TRUE,
        create_user_in         IN ref_orig_data.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN ref_orig_data.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN ref_orig_data.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN ref_orig_data.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN ref_orig_data.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN ref_orig_data.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        dt_create_in           IN ref_orig_data.dt_create%TYPE DEFAULT NULL,
        dt_create_nin          IN BOOLEAN := TRUE,
        where_in               VARCHAR2,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_professional_in     IN ref_orig_data.id_professional%TYPE DEFAULT NULL,
        id_professional_nin    IN BOOLEAN := TRUE,
        institution_name_in    IN ref_orig_data.institution_name%TYPE DEFAULT NULL,
        institution_name_nin   IN BOOLEAN := TRUE,
        create_user_in         IN ref_orig_data.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN ref_orig_data.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN ref_orig_data.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN ref_orig_data.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN ref_orig_data.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN ref_orig_data.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        dt_create_in           IN ref_orig_data.dt_create%TYPE DEFAULT NULL,
        dt_create_nin          IN BOOLEAN := TRUE,
        where_in               VARCHAR2,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_external_request_in IN ref_orig_data.id_external_request%TYPE,
        id_professional_in     IN ref_orig_data.id_professional%TYPE DEFAULT NULL,
        institution_name_in    IN ref_orig_data.institution_name%TYPE DEFAULT NULL,
        create_user_in         IN ref_orig_data.create_user%TYPE DEFAULT NULL,
        create_time_in         IN ref_orig_data.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN ref_orig_data.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN ref_orig_data.update_user%TYPE DEFAULT NULL,
        update_time_in         IN ref_orig_data.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN ref_orig_data.update_institution%TYPE DEFAULT NULL,
        dt_create_in           IN ref_orig_data.dt_create%TYPE DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_external_request_in IN ref_orig_data.id_external_request%TYPE,
        id_professional_in     IN ref_orig_data.id_professional%TYPE DEFAULT NULL,
        institution_name_in    IN ref_orig_data.institution_name%TYPE DEFAULT NULL,
        create_user_in         IN ref_orig_data.create_user%TYPE DEFAULT NULL,
        create_time_in         IN ref_orig_data.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN ref_orig_data.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN ref_orig_data.update_user%TYPE DEFAULT NULL,
        update_time_in         IN ref_orig_data.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN ref_orig_data.update_institution%TYPE DEFAULT NULL,
        dt_create_in           IN ref_orig_data.dt_create%TYPE DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN ref_orig_data%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN ref_orig_data%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN ref_orig_data_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN ref_orig_data_tc,
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
        id_external_request_in IN ref_orig_data.id_external_request%TYPE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_external_request_in IN ref_orig_data.id_external_request%TYPE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               OUT table_varchar
    );

    -- Delete all rows for primary key column ID_EXTERNAL_REQUEST
    PROCEDURE del_id_external_request
    (
        id_external_request_in IN ref_orig_data.id_external_request%TYPE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_EXTERNAL_REQUEST
    PROCEDURE del_id_external_request
    (
        id_external_request_in IN ref_orig_data.id_external_request%TYPE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               OUT table_varchar
    );

    -- Delete all rows for this RODA_ERTX_FK foreign key value
    PROCEDURE del_roda_ertx_fk
    (
        id_external_request_in IN ref_orig_data.id_external_request%TYPE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    -- Delete all rows for this RODA_ERTX_FK foreign key value
    PROCEDURE del_roda_ertx_fk
    (
        id_external_request_in IN ref_orig_data.id_external_request%TYPE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               OUT table_varchar
    );

    -- Delete all rows for this RODA_PROF_FK foreign key value
    PROCEDURE del_roda_prof_fk
    (
        id_professional_in IN ref_orig_data.id_professional%TYPE,
        handle_error_in    IN BOOLEAN := TRUE
    );

    -- Delete all rows for this RODA_PROF_FK foreign key value
    PROCEDURE del_roda_prof_fk
    (
        id_professional_in IN ref_orig_data.id_professional%TYPE,
        handle_error_in    IN BOOLEAN := TRUE,
        rows_out           OUT table_varchar
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
    PROCEDURE initrec(ref_orig_data_inout IN OUT ref_orig_data%ROWTYPE);

    FUNCTION initrec RETURN ref_orig_data%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN ref_orig_data_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN ref_orig_data_tc;

END ts_ref_orig_data;
/
