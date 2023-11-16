/*-- Last Change Revision: $Rev: 372225 $*/
/*-- Last Change by: $Author: claudio.ferreira $*/
/*-- Date of last change: $Date: 2010-01-08 10:42:48 +0000 (sex, 08 jan 2010) $*/


CREATE OR REPLACE PACKAGE ts_area_key_nextval
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: March 28, 2009 16:13:23
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "AREA_KEY_NEXTVAL"
    TYPE area_key_nextval_tc IS TABLE OF area_key_nextval%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE area_key_nextval_ntt IS TABLE OF area_key_nextval%ROWTYPE;
    TYPE area_key_nextval_vat IS VARRAY(100) OF area_key_nextval%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF area_key_nextval%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF area_key_nextval%ROWTYPE;
    TYPE vat IS VARRAY(100) OF area_key_nextval%ROWTYPE;

    -- Column Collection based on column "AREA"
    TYPE area_cc IS TABLE OF area_key_nextval.area%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "KEY"
    TYPE key_cc IS TABLE OF area_key_nextval.key%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CUR_VALUE"
    TYPE cur_value_cc IS TABLE OF area_key_nextval.cur_value%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        area_in      IN area_key_nextval.area%TYPE,
        key_in       IN area_key_nextval.key%TYPE,
        cur_value_in IN area_key_nextval.cur_value%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        area_in      IN area_key_nextval.area%TYPE,
        key_in       IN area_key_nextval.key%TYPE,
        cur_value_in IN area_key_nextval.cur_value%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    PROCEDURE ins
    (
        rec_in          IN area_key_nextval%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN area_key_nextval%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN area_key_nextval_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN area_key_nextval_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        area_in         IN area_key_nextval.area%TYPE,
        key_in          IN area_key_nextval.key%TYPE,
        cur_value_in    IN area_key_nextval.cur_value%TYPE DEFAULT NULL,
        cur_value_nin   IN BOOLEAN := TRUE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        area_in         IN area_key_nextval.area%TYPE,
        key_in          IN area_key_nextval.key%TYPE,
        cur_value_in    IN area_key_nextval.cur_value%TYPE DEFAULT NULL,
        cur_value_nin   IN BOOLEAN := TRUE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        cur_value_in    IN area_key_nextval.cur_value%TYPE DEFAULT NULL,
        cur_value_nin   IN BOOLEAN := TRUE,
        where_in        VARCHAR2 DEFAULT NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        cur_value_in    IN area_key_nextval.cur_value%TYPE DEFAULT NULL,
        cur_value_nin   IN BOOLEAN := TRUE,
        where_in        VARCHAR2 DEFAULT NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        area_in         IN area_key_nextval.area%TYPE,
        key_in          IN area_key_nextval.key%TYPE,
        cur_value_in    IN area_key_nextval.cur_value%TYPE DEFAULT NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        area_in         IN area_key_nextval.area%TYPE,
        key_in          IN area_key_nextval.key%TYPE,
        cur_value_in    IN area_key_nextval.cur_value%TYPE DEFAULT NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN area_key_nextval%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN area_key_nextval%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN area_key_nextval_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN area_key_nextval_tc,
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
        area_in         IN area_key_nextval.area%TYPE,
        key_in          IN area_key_nextval.key%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        area_in         IN area_key_nextval.area%TYPE,
        key_in          IN area_key_nextval.key%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for primary key column AREA
    PROCEDURE del_area
    (
        area_in         IN area_key_nextval.area%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column AREA
    PROCEDURE del_area
    (
        area_in         IN area_key_nextval.area%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for primary key column KEY
    PROCEDURE del_key
    (
        key_in          IN area_key_nextval.key%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column KEY
    PROCEDURE del_key
    (
        key_in          IN area_key_nextval.key%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
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
    PROCEDURE initrec(area_key_nextval_inout IN OUT area_key_nextval%ROWTYPE);

    FUNCTION initrec RETURN area_key_nextval%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN area_key_nextval_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN area_key_nextval_tc;

END ts_area_key_nextval;
/