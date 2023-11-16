/*-- Last Change Revision: $Rev: 1510293 $*/
/*-- Last Change by: $Author: sofia.mendes $*/
/*-- Date of last change: $Date: 2013-10-03 15:36:08 +0100 (qui, 03 out 2013) $*/
CREATE OR REPLACE PACKAGE ts_epis_hidrics_group
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: September 24, 2013 8:54:21
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "EPIS_HIDRICS_GROUP"
    TYPE epis_hidrics_group_tc IS TABLE OF epis_hidrics_group%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE epis_hidrics_group_ntt IS TABLE OF epis_hidrics_group%ROWTYPE;
    TYPE epis_hidrics_group_vat IS VARRAY(100) OF epis_hidrics_group%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF epis_hidrics_group%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF epis_hidrics_group%ROWTYPE;
    TYPE vat IS VARRAY(100) OF epis_hidrics_group%ROWTYPE;

    -- Column Collection based on column "ID_EPIS_HIDRICS_GROUP"
    TYPE id_epis_hidrics_group_cc IS TABLE OF epis_hidrics_group.id_epis_hidrics_group%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "GROUP_DESC"
    TYPE group_desc_cc IS TABLE OF epis_hidrics_group.group_desc%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_USER"
    TYPE create_user_cc IS TABLE OF epis_hidrics_group.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_TIME"
    TYPE create_time_cc IS TABLE OF epis_hidrics_group.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_INSTITUTION"
    TYPE create_institution_cc IS TABLE OF epis_hidrics_group.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_USER"
    TYPE update_user_cc IS TABLE OF epis_hidrics_group.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_TIME"
    TYPE update_time_cc IS TABLE OF epis_hidrics_group.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_INSTITUTION"
    TYPE update_institution_cc IS TABLE OF epis_hidrics_group.update_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_STATUS"
    TYPE flg_status_cc IS TABLE OF epis_hidrics_group.flg_status%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_epis_hidrics_group_in IN epis_hidrics_group.id_epis_hidrics_group%TYPE,
        group_desc_in            IN epis_hidrics_group.group_desc%TYPE DEFAULT NULL,
        create_user_in           IN epis_hidrics_group.create_user%TYPE DEFAULT NULL,
        create_time_in           IN epis_hidrics_group.create_time%TYPE DEFAULT NULL,
        create_institution_in    IN epis_hidrics_group.create_institution%TYPE DEFAULT NULL,
        update_user_in           IN epis_hidrics_group.update_user%TYPE DEFAULT NULL,
        update_time_in           IN epis_hidrics_group.update_time%TYPE DEFAULT NULL,
        update_institution_in    IN epis_hidrics_group.update_institution%TYPE DEFAULT NULL,
        flg_status_in            IN epis_hidrics_group.flg_status%TYPE DEFAULT 'A'
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_epis_hidrics_group_in IN epis_hidrics_group.id_epis_hidrics_group%TYPE,
        group_desc_in            IN epis_hidrics_group.group_desc%TYPE DEFAULT NULL,
        create_user_in           IN epis_hidrics_group.create_user%TYPE DEFAULT NULL,
        create_time_in           IN epis_hidrics_group.create_time%TYPE DEFAULT NULL,
        create_institution_in    IN epis_hidrics_group.create_institution%TYPE DEFAULT NULL,
        update_user_in           IN epis_hidrics_group.update_user%TYPE DEFAULT NULL,
        update_time_in           IN epis_hidrics_group.update_time%TYPE DEFAULT NULL,
        update_institution_in    IN epis_hidrics_group.update_institution%TYPE DEFAULT NULL,
        flg_status_in            IN epis_hidrics_group.flg_status%TYPE DEFAULT 'A'
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    -- Specify whether or not a primary key value should be generated.
    PROCEDURE ins
    (
        rec_in          IN epis_hidrics_group%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN epis_hidrics_group%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN epis_hidrics_group_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN epis_hidrics_group_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Return next primary key value using the named sequence.
    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN epis_hidrics_group.id_epis_hidrics_group%TYPE;

    -- Insert one row, generating hidden primary key using a sequence
    PROCEDURE ins
    (
        group_desc_in         IN epis_hidrics_group.group_desc%TYPE DEFAULT NULL,
        create_user_in        IN epis_hidrics_group.create_user%TYPE DEFAULT NULL,
        create_time_in        IN epis_hidrics_group.create_time%TYPE DEFAULT NULL,
        create_institution_in IN epis_hidrics_group.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN epis_hidrics_group.update_user%TYPE DEFAULT NULL,
        update_time_in        IN epis_hidrics_group.update_time%TYPE DEFAULT NULL,
        update_institution_in IN epis_hidrics_group.update_institution%TYPE DEFAULT NULL,
        flg_status_in         IN epis_hidrics_group.flg_status%TYPE DEFAULT 'A'
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        group_desc_in         IN epis_hidrics_group.group_desc%TYPE DEFAULT NULL,
        create_user_in        IN epis_hidrics_group.create_user%TYPE DEFAULT NULL,
        create_time_in        IN epis_hidrics_group.create_time%TYPE DEFAULT NULL,
        create_institution_in IN epis_hidrics_group.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN epis_hidrics_group.update_user%TYPE DEFAULT NULL,
        update_time_in        IN epis_hidrics_group.update_time%TYPE DEFAULT NULL,
        update_institution_in IN epis_hidrics_group.update_institution%TYPE DEFAULT NULL,
        flg_status_in         IN epis_hidrics_group.flg_status%TYPE DEFAULT 'A'
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row, returning primary key generated by sequence
    PROCEDURE ins
    (
        group_desc_in             IN epis_hidrics_group.group_desc%TYPE DEFAULT NULL,
        create_user_in            IN epis_hidrics_group.create_user%TYPE DEFAULT NULL,
        create_time_in            IN epis_hidrics_group.create_time%TYPE DEFAULT NULL,
        create_institution_in     IN epis_hidrics_group.create_institution%TYPE DEFAULT NULL,
        update_user_in            IN epis_hidrics_group.update_user%TYPE DEFAULT NULL,
        update_time_in            IN epis_hidrics_group.update_time%TYPE DEFAULT NULL,
        update_institution_in     IN epis_hidrics_group.update_institution%TYPE DEFAULT NULL,
        flg_status_in             IN epis_hidrics_group.flg_status%TYPE DEFAULT 'A',
        id_epis_hidrics_group_out IN OUT epis_hidrics_group.id_epis_hidrics_group%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        group_desc_in             IN epis_hidrics_group.group_desc%TYPE DEFAULT NULL,
        create_user_in            IN epis_hidrics_group.create_user%TYPE DEFAULT NULL,
        create_time_in            IN epis_hidrics_group.create_time%TYPE DEFAULT NULL,
        create_institution_in     IN epis_hidrics_group.create_institution%TYPE DEFAULT NULL,
        update_user_in            IN epis_hidrics_group.update_user%TYPE DEFAULT NULL,
        update_time_in            IN epis_hidrics_group.update_time%TYPE DEFAULT NULL,
        update_institution_in     IN epis_hidrics_group.update_institution%TYPE DEFAULT NULL,
        flg_status_in             IN epis_hidrics_group.flg_status%TYPE DEFAULT 'A',
        id_epis_hidrics_group_out IN OUT epis_hidrics_group.id_epis_hidrics_group%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row with function, return generated primary key
    FUNCTION ins
    (
        group_desc_in         IN epis_hidrics_group.group_desc%TYPE DEFAULT NULL,
        create_user_in        IN epis_hidrics_group.create_user%TYPE DEFAULT NULL,
        create_time_in        IN epis_hidrics_group.create_time%TYPE DEFAULT NULL,
        create_institution_in IN epis_hidrics_group.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN epis_hidrics_group.update_user%TYPE DEFAULT NULL,
        update_time_in        IN epis_hidrics_group.update_time%TYPE DEFAULT NULL,
        update_institution_in IN epis_hidrics_group.update_institution%TYPE DEFAULT NULL,
        flg_status_in         IN epis_hidrics_group.flg_status%TYPE DEFAULT 'A'
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    ) RETURN epis_hidrics_group.id_epis_hidrics_group%TYPE;

    FUNCTION ins
    (
        group_desc_in         IN epis_hidrics_group.group_desc%TYPE DEFAULT NULL,
        create_user_in        IN epis_hidrics_group.create_user%TYPE DEFAULT NULL,
        create_time_in        IN epis_hidrics_group.create_time%TYPE DEFAULT NULL,
        create_institution_in IN epis_hidrics_group.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN epis_hidrics_group.update_user%TYPE DEFAULT NULL,
        update_time_in        IN epis_hidrics_group.update_time%TYPE DEFAULT NULL,
        update_institution_in IN epis_hidrics_group.update_institution%TYPE DEFAULT NULL,
        flg_status_in         IN epis_hidrics_group.flg_status%TYPE DEFAULT 'A'
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    ) RETURN epis_hidrics_group.id_epis_hidrics_group%TYPE;

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        id_epis_hidrics_group_in IN epis_hidrics_group.id_epis_hidrics_group%TYPE,
        group_desc_in            IN epis_hidrics_group.group_desc%TYPE DEFAULT NULL,
        group_desc_nin           IN BOOLEAN := TRUE,
        create_user_in           IN epis_hidrics_group.create_user%TYPE DEFAULT NULL,
        create_user_nin          IN BOOLEAN := TRUE,
        create_time_in           IN epis_hidrics_group.create_time%TYPE DEFAULT NULL,
        create_time_nin          IN BOOLEAN := TRUE,
        create_institution_in    IN epis_hidrics_group.create_institution%TYPE DEFAULT NULL,
        create_institution_nin   IN BOOLEAN := TRUE,
        update_user_in           IN epis_hidrics_group.update_user%TYPE DEFAULT NULL,
        update_user_nin          IN BOOLEAN := TRUE,
        update_time_in           IN epis_hidrics_group.update_time%TYPE DEFAULT NULL,
        update_time_nin          IN BOOLEAN := TRUE,
        update_institution_in    IN epis_hidrics_group.update_institution%TYPE DEFAULT NULL,
        update_institution_nin   IN BOOLEAN := TRUE,
        flg_status_in            IN epis_hidrics_group.flg_status%TYPE DEFAULT NULL,
        flg_status_nin           IN BOOLEAN := TRUE,
        handle_error_in          IN BOOLEAN := TRUE,
        rows_out                 IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_epis_hidrics_group_in IN epis_hidrics_group.id_epis_hidrics_group%TYPE,
        group_desc_in            IN epis_hidrics_group.group_desc%TYPE DEFAULT NULL,
        group_desc_nin           IN BOOLEAN := TRUE,
        create_user_in           IN epis_hidrics_group.create_user%TYPE DEFAULT NULL,
        create_user_nin          IN BOOLEAN := TRUE,
        create_time_in           IN epis_hidrics_group.create_time%TYPE DEFAULT NULL,
        create_time_nin          IN BOOLEAN := TRUE,
        create_institution_in    IN epis_hidrics_group.create_institution%TYPE DEFAULT NULL,
        create_institution_nin   IN BOOLEAN := TRUE,
        update_user_in           IN epis_hidrics_group.update_user%TYPE DEFAULT NULL,
        update_user_nin          IN BOOLEAN := TRUE,
        update_time_in           IN epis_hidrics_group.update_time%TYPE DEFAULT NULL,
        update_time_nin          IN BOOLEAN := TRUE,
        update_institution_in    IN epis_hidrics_group.update_institution%TYPE DEFAULT NULL,
        update_institution_nin   IN BOOLEAN := TRUE,
        flg_status_in            IN epis_hidrics_group.flg_status%TYPE DEFAULT NULL,
        flg_status_nin           IN BOOLEAN := TRUE,
        handle_error_in          IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        group_desc_in          IN epis_hidrics_group.group_desc%TYPE DEFAULT NULL,
        group_desc_nin         IN BOOLEAN := TRUE,
        create_user_in         IN epis_hidrics_group.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN epis_hidrics_group.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN epis_hidrics_group.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN epis_hidrics_group.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN epis_hidrics_group.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN epis_hidrics_group.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        flg_status_in          IN epis_hidrics_group.flg_status%TYPE DEFAULT NULL,
        flg_status_nin         IN BOOLEAN := TRUE,
        where_in               VARCHAR2,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    PROCEDURE upd
    (
        group_desc_in          IN epis_hidrics_group.group_desc%TYPE DEFAULT NULL,
        group_desc_nin         IN BOOLEAN := TRUE,
        create_user_in         IN epis_hidrics_group.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN epis_hidrics_group.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN epis_hidrics_group.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN epis_hidrics_group.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN epis_hidrics_group.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN epis_hidrics_group.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        flg_status_in          IN epis_hidrics_group.flg_status%TYPE DEFAULT NULL,
        flg_status_nin         IN BOOLEAN := TRUE,
        where_in               VARCHAR2,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_epis_hidrics_group_in IN epis_hidrics_group.id_epis_hidrics_group%TYPE,
        group_desc_in            IN epis_hidrics_group.group_desc%TYPE DEFAULT NULL,
        create_user_in           IN epis_hidrics_group.create_user%TYPE DEFAULT NULL,
        create_time_in           IN epis_hidrics_group.create_time%TYPE DEFAULT NULL,
        create_institution_in    IN epis_hidrics_group.create_institution%TYPE DEFAULT NULL,
        update_user_in           IN epis_hidrics_group.update_user%TYPE DEFAULT NULL,
        update_time_in           IN epis_hidrics_group.update_time%TYPE DEFAULT NULL,
        update_institution_in    IN epis_hidrics_group.update_institution%TYPE DEFAULT NULL,
        flg_status_in            IN epis_hidrics_group.flg_status%TYPE DEFAULT NULL,
        handle_error_in          IN BOOLEAN := TRUE,
        rows_out                 OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_epis_hidrics_group_in IN epis_hidrics_group.id_epis_hidrics_group%TYPE,
        group_desc_in            IN epis_hidrics_group.group_desc%TYPE DEFAULT NULL,
        create_user_in           IN epis_hidrics_group.create_user%TYPE DEFAULT NULL,
        create_time_in           IN epis_hidrics_group.create_time%TYPE DEFAULT NULL,
        create_institution_in    IN epis_hidrics_group.create_institution%TYPE DEFAULT NULL,
        update_user_in           IN epis_hidrics_group.update_user%TYPE DEFAULT NULL,
        update_time_in           IN epis_hidrics_group.update_time%TYPE DEFAULT NULL,
        update_institution_in    IN epis_hidrics_group.update_institution%TYPE DEFAULT NULL,
        flg_status_in            IN epis_hidrics_group.flg_status%TYPE DEFAULT NULL,
        handle_error_in          IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN epis_hidrics_group%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN epis_hidrics_group%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN epis_hidrics_group_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN epis_hidrics_group_tc,
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
        id_epis_hidrics_group_in IN epis_hidrics_group.id_epis_hidrics_group%TYPE,
        handle_error_in          IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_epis_hidrics_group_in IN epis_hidrics_group.id_epis_hidrics_group%TYPE,
        handle_error_in          IN BOOLEAN := TRUE,
        rows_out                 OUT table_varchar
    );

    -- Delete all rows for primary key column ID_EPIS_HIDRICS_GROUP
    PROCEDURE del_id_epis_hidrics_group
    (
        id_epis_hidrics_group_in IN epis_hidrics_group.id_epis_hidrics_group%TYPE,
        handle_error_in          IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_EPIS_HIDRICS_GROUP
    PROCEDURE del_id_epis_hidrics_group
    (
        id_epis_hidrics_group_in IN epis_hidrics_group.id_epis_hidrics_group%TYPE,
        handle_error_in          IN BOOLEAN := TRUE,
        rows_out                 OUT table_varchar
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
    PROCEDURE initrec(epis_hidrics_group_inout IN OUT epis_hidrics_group%ROWTYPE);

    FUNCTION initrec RETURN epis_hidrics_group%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN epis_hidrics_group_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN epis_hidrics_group_tc;

END ts_epis_hidrics_group;
/
