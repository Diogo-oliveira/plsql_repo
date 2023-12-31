/*-- Last Change Revision: $Rev: 2029349 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:51:11 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE ts_rehab_plan_area
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Dezembro 23, 2010 11:27:8
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "REHAB_PLAN_AREA"
    TYPE rehab_plan_area_tc IS TABLE OF rehab_plan_area%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE rehab_plan_area_ntt IS TABLE OF rehab_plan_area%ROWTYPE;
    TYPE rehab_plan_area_vat IS VARRAY(100) OF rehab_plan_area%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF rehab_plan_area%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF rehab_plan_area%ROWTYPE;
    TYPE vat IS VARRAY(100) OF rehab_plan_area%ROWTYPE;

    -- Column Collection based on column "ID_REHAB_PLAN_AREA"
    TYPE id_rehab_plan_area_cc IS TABLE OF rehab_plan_area.id_rehab_plan_area%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CODE_REHAB_PLAN_AREA"
    TYPE code_rehab_plan_area_cc IS TABLE OF rehab_plan_area.code_rehab_plan_area%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_AVAILABLE"
    TYPE flg_available_cc IS TABLE OF rehab_plan_area.flg_available%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_CONTENT"
    TYPE id_content_cc IS TABLE OF rehab_plan_area.id_content%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "RANK"
    TYPE rank_cc IS TABLE OF rehab_plan_area.rank%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_USER"
    TYPE create_user_cc IS TABLE OF rehab_plan_area.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_TIME"
    TYPE create_time_cc IS TABLE OF rehab_plan_area.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_INSTITUTION"
    TYPE create_institution_cc IS TABLE OF rehab_plan_area.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_USER"
    TYPE update_user_cc IS TABLE OF rehab_plan_area.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_TIME"
    TYPE update_time_cc IS TABLE OF rehab_plan_area.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_INSTITUTION"
    TYPE update_institution_cc IS TABLE OF rehab_plan_area.update_institution%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_rehab_plan_area_in   IN rehab_plan_area.id_rehab_plan_area%TYPE,
        code_rehab_plan_area_in IN rehab_plan_area.code_rehab_plan_area%TYPE DEFAULT NULL,
        flg_available_in        IN rehab_plan_area.flg_available%TYPE DEFAULT 'Y',
        id_content_in           IN rehab_plan_area.id_content%TYPE DEFAULT NULL,
        rank_in                 IN rehab_plan_area.rank%TYPE DEFAULT NULL,
        create_user_in          IN rehab_plan_area.create_user%TYPE DEFAULT NULL,
        create_time_in          IN rehab_plan_area.create_time%TYPE DEFAULT NULL,
        create_institution_in   IN rehab_plan_area.create_institution%TYPE DEFAULT NULL,
        update_user_in          IN rehab_plan_area.update_user%TYPE DEFAULT NULL,
        update_time_in          IN rehab_plan_area.update_time%TYPE DEFAULT NULL,
        update_institution_in   IN rehab_plan_area.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_rehab_plan_area_in   IN rehab_plan_area.id_rehab_plan_area%TYPE,
        code_rehab_plan_area_in IN rehab_plan_area.code_rehab_plan_area%TYPE DEFAULT NULL,
        flg_available_in        IN rehab_plan_area.flg_available%TYPE DEFAULT 'Y',
        id_content_in           IN rehab_plan_area.id_content%TYPE DEFAULT NULL,
        rank_in                 IN rehab_plan_area.rank%TYPE DEFAULT NULL,
        create_user_in          IN rehab_plan_area.create_user%TYPE DEFAULT NULL,
        create_time_in          IN rehab_plan_area.create_time%TYPE DEFAULT NULL,
        create_institution_in   IN rehab_plan_area.create_institution%TYPE DEFAULT NULL,
        update_user_in          IN rehab_plan_area.update_user%TYPE DEFAULT NULL,
        update_time_in          IN rehab_plan_area.update_time%TYPE DEFAULT NULL,
        update_institution_in   IN rehab_plan_area.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    -- Specify whether or not a primary key value should be generated.
    PROCEDURE ins
    (
        rec_in          IN rehab_plan_area%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN rehab_plan_area%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN rehab_plan_area_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN rehab_plan_area_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Return next primary key value using the named sequence.
    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN rehab_plan_area.id_rehab_plan_area%TYPE;

    -- Insert one row, generating hidden primary key using a sequence
    PROCEDURE ins
    (
        code_rehab_plan_area_in IN rehab_plan_area.code_rehab_plan_area%TYPE DEFAULT NULL,
        flg_available_in        IN rehab_plan_area.flg_available%TYPE DEFAULT 'Y',
        id_content_in           IN rehab_plan_area.id_content%TYPE DEFAULT NULL,
        rank_in                 IN rehab_plan_area.rank%TYPE DEFAULT NULL,
        create_user_in          IN rehab_plan_area.create_user%TYPE DEFAULT NULL,
        create_time_in          IN rehab_plan_area.create_time%TYPE DEFAULT NULL,
        create_institution_in   IN rehab_plan_area.create_institution%TYPE DEFAULT NULL,
        update_user_in          IN rehab_plan_area.update_user%TYPE DEFAULT NULL,
        update_time_in          IN rehab_plan_area.update_time%TYPE DEFAULT NULL,
        update_institution_in   IN rehab_plan_area.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        code_rehab_plan_area_in IN rehab_plan_area.code_rehab_plan_area%TYPE DEFAULT NULL,
        flg_available_in        IN rehab_plan_area.flg_available%TYPE DEFAULT 'Y',
        id_content_in           IN rehab_plan_area.id_content%TYPE DEFAULT NULL,
        rank_in                 IN rehab_plan_area.rank%TYPE DEFAULT NULL,
        create_user_in          IN rehab_plan_area.create_user%TYPE DEFAULT NULL,
        create_time_in          IN rehab_plan_area.create_time%TYPE DEFAULT NULL,
        create_institution_in   IN rehab_plan_area.create_institution%TYPE DEFAULT NULL,
        update_user_in          IN rehab_plan_area.update_user%TYPE DEFAULT NULL,
        update_time_in          IN rehab_plan_area.update_time%TYPE DEFAULT NULL,
        update_institution_in   IN rehab_plan_area.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row, returning primary key generated by sequence
    PROCEDURE ins
    (
        code_rehab_plan_area_in IN rehab_plan_area.code_rehab_plan_area%TYPE DEFAULT NULL,
        flg_available_in        IN rehab_plan_area.flg_available%TYPE DEFAULT 'Y',
        id_content_in           IN rehab_plan_area.id_content%TYPE DEFAULT NULL,
        rank_in                 IN rehab_plan_area.rank%TYPE DEFAULT NULL,
        create_user_in          IN rehab_plan_area.create_user%TYPE DEFAULT NULL,
        create_time_in          IN rehab_plan_area.create_time%TYPE DEFAULT NULL,
        create_institution_in   IN rehab_plan_area.create_institution%TYPE DEFAULT NULL,
        update_user_in          IN rehab_plan_area.update_user%TYPE DEFAULT NULL,
        update_time_in          IN rehab_plan_area.update_time%TYPE DEFAULT NULL,
        update_institution_in   IN rehab_plan_area.update_institution%TYPE DEFAULT NULL,
        id_rehab_plan_area_out  IN OUT rehab_plan_area.id_rehab_plan_area%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        code_rehab_plan_area_in IN rehab_plan_area.code_rehab_plan_area%TYPE DEFAULT NULL,
        flg_available_in        IN rehab_plan_area.flg_available%TYPE DEFAULT 'Y',
        id_content_in           IN rehab_plan_area.id_content%TYPE DEFAULT NULL,
        rank_in                 IN rehab_plan_area.rank%TYPE DEFAULT NULL,
        create_user_in          IN rehab_plan_area.create_user%TYPE DEFAULT NULL,
        create_time_in          IN rehab_plan_area.create_time%TYPE DEFAULT NULL,
        create_institution_in   IN rehab_plan_area.create_institution%TYPE DEFAULT NULL,
        update_user_in          IN rehab_plan_area.update_user%TYPE DEFAULT NULL,
        update_time_in          IN rehab_plan_area.update_time%TYPE DEFAULT NULL,
        update_institution_in   IN rehab_plan_area.update_institution%TYPE DEFAULT NULL,
        id_rehab_plan_area_out  IN OUT rehab_plan_area.id_rehab_plan_area%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row with function, return generated primary key
    FUNCTION ins
    (
        code_rehab_plan_area_in IN rehab_plan_area.code_rehab_plan_area%TYPE DEFAULT NULL,
        flg_available_in        IN rehab_plan_area.flg_available%TYPE DEFAULT 'Y',
        id_content_in           IN rehab_plan_area.id_content%TYPE DEFAULT NULL,
        rank_in                 IN rehab_plan_area.rank%TYPE DEFAULT NULL,
        create_user_in          IN rehab_plan_area.create_user%TYPE DEFAULT NULL,
        create_time_in          IN rehab_plan_area.create_time%TYPE DEFAULT NULL,
        create_institution_in   IN rehab_plan_area.create_institution%TYPE DEFAULT NULL,
        update_user_in          IN rehab_plan_area.update_user%TYPE DEFAULT NULL,
        update_time_in          IN rehab_plan_area.update_time%TYPE DEFAULT NULL,
        update_institution_in   IN rehab_plan_area.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    ) RETURN rehab_plan_area.id_rehab_plan_area%TYPE;

    FUNCTION ins
    (
        code_rehab_plan_area_in IN rehab_plan_area.code_rehab_plan_area%TYPE DEFAULT NULL,
        flg_available_in        IN rehab_plan_area.flg_available%TYPE DEFAULT 'Y',
        id_content_in           IN rehab_plan_area.id_content%TYPE DEFAULT NULL,
        rank_in                 IN rehab_plan_area.rank%TYPE DEFAULT NULL,
        create_user_in          IN rehab_plan_area.create_user%TYPE DEFAULT NULL,
        create_time_in          IN rehab_plan_area.create_time%TYPE DEFAULT NULL,
        create_institution_in   IN rehab_plan_area.create_institution%TYPE DEFAULT NULL,
        update_user_in          IN rehab_plan_area.update_user%TYPE DEFAULT NULL,
        update_time_in          IN rehab_plan_area.update_time%TYPE DEFAULT NULL,
        update_institution_in   IN rehab_plan_area.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    ) RETURN rehab_plan_area.id_rehab_plan_area%TYPE;

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        id_rehab_plan_area_in    IN rehab_plan_area.id_rehab_plan_area%TYPE,
        code_rehab_plan_area_in  IN rehab_plan_area.code_rehab_plan_area%TYPE DEFAULT NULL,
        code_rehab_plan_area_nin IN BOOLEAN := TRUE,
        flg_available_in         IN rehab_plan_area.flg_available%TYPE DEFAULT NULL,
        flg_available_nin        IN BOOLEAN := TRUE,
        id_content_in            IN rehab_plan_area.id_content%TYPE DEFAULT NULL,
        id_content_nin           IN BOOLEAN := TRUE,
        rank_in                  IN rehab_plan_area.rank%TYPE DEFAULT NULL,
        rank_nin                 IN BOOLEAN := TRUE,
        create_user_in           IN rehab_plan_area.create_user%TYPE DEFAULT NULL,
        create_user_nin          IN BOOLEAN := TRUE,
        create_time_in           IN rehab_plan_area.create_time%TYPE DEFAULT NULL,
        create_time_nin          IN BOOLEAN := TRUE,
        create_institution_in    IN rehab_plan_area.create_institution%TYPE DEFAULT NULL,
        create_institution_nin   IN BOOLEAN := TRUE,
        update_user_in           IN rehab_plan_area.update_user%TYPE DEFAULT NULL,
        update_user_nin          IN BOOLEAN := TRUE,
        update_time_in           IN rehab_plan_area.update_time%TYPE DEFAULT NULL,
        update_time_nin          IN BOOLEAN := TRUE,
        update_institution_in    IN rehab_plan_area.update_institution%TYPE DEFAULT NULL,
        update_institution_nin   IN BOOLEAN := TRUE,
        handle_error_in          IN BOOLEAN := TRUE,
        rows_out                 IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_rehab_plan_area_in    IN rehab_plan_area.id_rehab_plan_area%TYPE,
        code_rehab_plan_area_in  IN rehab_plan_area.code_rehab_plan_area%TYPE DEFAULT NULL,
        code_rehab_plan_area_nin IN BOOLEAN := TRUE,
        flg_available_in         IN rehab_plan_area.flg_available%TYPE DEFAULT NULL,
        flg_available_nin        IN BOOLEAN := TRUE,
        id_content_in            IN rehab_plan_area.id_content%TYPE DEFAULT NULL,
        id_content_nin           IN BOOLEAN := TRUE,
        rank_in                  IN rehab_plan_area.rank%TYPE DEFAULT NULL,
        rank_nin                 IN BOOLEAN := TRUE,
        create_user_in           IN rehab_plan_area.create_user%TYPE DEFAULT NULL,
        create_user_nin          IN BOOLEAN := TRUE,
        create_time_in           IN rehab_plan_area.create_time%TYPE DEFAULT NULL,
        create_time_nin          IN BOOLEAN := TRUE,
        create_institution_in    IN rehab_plan_area.create_institution%TYPE DEFAULT NULL,
        create_institution_nin   IN BOOLEAN := TRUE,
        update_user_in           IN rehab_plan_area.update_user%TYPE DEFAULT NULL,
        update_user_nin          IN BOOLEAN := TRUE,
        update_time_in           IN rehab_plan_area.update_time%TYPE DEFAULT NULL,
        update_time_nin          IN BOOLEAN := TRUE,
        update_institution_in    IN rehab_plan_area.update_institution%TYPE DEFAULT NULL,
        update_institution_nin   IN BOOLEAN := TRUE,
        handle_error_in          IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        code_rehab_plan_area_in  IN rehab_plan_area.code_rehab_plan_area%TYPE DEFAULT NULL,
        code_rehab_plan_area_nin IN BOOLEAN := TRUE,
        flg_available_in         IN rehab_plan_area.flg_available%TYPE DEFAULT NULL,
        flg_available_nin        IN BOOLEAN := TRUE,
        id_content_in            IN rehab_plan_area.id_content%TYPE DEFAULT NULL,
        id_content_nin           IN BOOLEAN := TRUE,
        rank_in                  IN rehab_plan_area.rank%TYPE DEFAULT NULL,
        rank_nin                 IN BOOLEAN := TRUE,
        create_user_in           IN rehab_plan_area.create_user%TYPE DEFAULT NULL,
        create_user_nin          IN BOOLEAN := TRUE,
        create_time_in           IN rehab_plan_area.create_time%TYPE DEFAULT NULL,
        create_time_nin          IN BOOLEAN := TRUE,
        create_institution_in    IN rehab_plan_area.create_institution%TYPE DEFAULT NULL,
        create_institution_nin   IN BOOLEAN := TRUE,
        update_user_in           IN rehab_plan_area.update_user%TYPE DEFAULT NULL,
        update_user_nin          IN BOOLEAN := TRUE,
        update_time_in           IN rehab_plan_area.update_time%TYPE DEFAULT NULL,
        update_time_nin          IN BOOLEAN := TRUE,
        update_institution_in    IN rehab_plan_area.update_institution%TYPE DEFAULT NULL,
        update_institution_nin   IN BOOLEAN := TRUE,
        where_in                 VARCHAR2 DEFAULT NULL,
        handle_error_in          IN BOOLEAN := TRUE,
        rows_out                 IN OUT table_varchar
    );

    PROCEDURE upd
    (
        code_rehab_plan_area_in  IN rehab_plan_area.code_rehab_plan_area%TYPE DEFAULT NULL,
        code_rehab_plan_area_nin IN BOOLEAN := TRUE,
        flg_available_in         IN rehab_plan_area.flg_available%TYPE DEFAULT NULL,
        flg_available_nin        IN BOOLEAN := TRUE,
        id_content_in            IN rehab_plan_area.id_content%TYPE DEFAULT NULL,
        id_content_nin           IN BOOLEAN := TRUE,
        rank_in                  IN rehab_plan_area.rank%TYPE DEFAULT NULL,
        rank_nin                 IN BOOLEAN := TRUE,
        create_user_in           IN rehab_plan_area.create_user%TYPE DEFAULT NULL,
        create_user_nin          IN BOOLEAN := TRUE,
        create_time_in           IN rehab_plan_area.create_time%TYPE DEFAULT NULL,
        create_time_nin          IN BOOLEAN := TRUE,
        create_institution_in    IN rehab_plan_area.create_institution%TYPE DEFAULT NULL,
        create_institution_nin   IN BOOLEAN := TRUE,
        update_user_in           IN rehab_plan_area.update_user%TYPE DEFAULT NULL,
        update_user_nin          IN BOOLEAN := TRUE,
        update_time_in           IN rehab_plan_area.update_time%TYPE DEFAULT NULL,
        update_time_nin          IN BOOLEAN := TRUE,
        update_institution_in    IN rehab_plan_area.update_institution%TYPE DEFAULT NULL,
        update_institution_nin   IN BOOLEAN := TRUE,
        where_in                 VARCHAR2 DEFAULT NULL,
        handle_error_in          IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_rehab_plan_area_in   IN rehab_plan_area.id_rehab_plan_area%TYPE,
        code_rehab_plan_area_in IN rehab_plan_area.code_rehab_plan_area%TYPE DEFAULT NULL,
        flg_available_in        IN rehab_plan_area.flg_available%TYPE DEFAULT NULL,
        id_content_in           IN rehab_plan_area.id_content%TYPE DEFAULT NULL,
        rank_in                 IN rehab_plan_area.rank%TYPE DEFAULT NULL,
        create_user_in          IN rehab_plan_area.create_user%TYPE DEFAULT NULL,
        create_time_in          IN rehab_plan_area.create_time%TYPE DEFAULT NULL,
        create_institution_in   IN rehab_plan_area.create_institution%TYPE DEFAULT NULL,
        update_user_in          IN rehab_plan_area.update_user%TYPE DEFAULT NULL,
        update_time_in          IN rehab_plan_area.update_time%TYPE DEFAULT NULL,
        update_institution_in   IN rehab_plan_area.update_institution%TYPE DEFAULT NULL,
        handle_error_in         IN BOOLEAN := TRUE,
        rows_out                OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_rehab_plan_area_in   IN rehab_plan_area.id_rehab_plan_area%TYPE,
        code_rehab_plan_area_in IN rehab_plan_area.code_rehab_plan_area%TYPE DEFAULT NULL,
        flg_available_in        IN rehab_plan_area.flg_available%TYPE DEFAULT NULL,
        id_content_in           IN rehab_plan_area.id_content%TYPE DEFAULT NULL,
        rank_in                 IN rehab_plan_area.rank%TYPE DEFAULT NULL,
        create_user_in          IN rehab_plan_area.create_user%TYPE DEFAULT NULL,
        create_time_in          IN rehab_plan_area.create_time%TYPE DEFAULT NULL,
        create_institution_in   IN rehab_plan_area.create_institution%TYPE DEFAULT NULL,
        update_user_in          IN rehab_plan_area.update_user%TYPE DEFAULT NULL,
        update_time_in          IN rehab_plan_area.update_time%TYPE DEFAULT NULL,
        update_institution_in   IN rehab_plan_area.update_institution%TYPE DEFAULT NULL,
        handle_error_in         IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN rehab_plan_area%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN rehab_plan_area%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN rehab_plan_area_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN rehab_plan_area_tc,
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
        id_rehab_plan_area_in IN rehab_plan_area.id_rehab_plan_area%TYPE,
        handle_error_in       IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_rehab_plan_area_in IN rehab_plan_area.id_rehab_plan_area%TYPE,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
    );

    -- Delete all rows for primary key column ID_REHAB_PLAN_AREA
    PROCEDURE del_id_rehab_plan_area
    (
        id_rehab_plan_area_in IN rehab_plan_area.id_rehab_plan_area%TYPE,
        handle_error_in       IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_REHAB_PLAN_AREA
    PROCEDURE del_id_rehab_plan_area
    (
        id_rehab_plan_area_in IN rehab_plan_area.id_rehab_plan_area%TYPE,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
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
    PROCEDURE initrec(rehab_plan_area_inout IN OUT rehab_plan_area%ROWTYPE);

    FUNCTION initrec RETURN rehab_plan_area%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN rehab_plan_area_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN rehab_plan_area_tc;

END ts_rehab_plan_area;
/
