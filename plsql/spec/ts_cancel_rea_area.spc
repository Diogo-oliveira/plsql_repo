/*-- Last Change Revision: $Rev: 372225 $*/
/*-- Last Change by: $Author: claudio.ferreira $*/
/*-- Date of last change: $Date: 2010-01-08 10:42:48 +0000 (sex, 08 jan 2010) $*/

CREATE OR REPLACE PACKAGE ts_cancel_rea_area
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: January 22, 2009 19:49:10
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "CANCEL_REA_AREA"
    TYPE cancel_rea_area_tc IS TABLE OF cancel_rea_area%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE cancel_rea_area_ntt IS TABLE OF cancel_rea_area%ROWTYPE;
    TYPE cancel_rea_area_vat IS VARRAY(100) OF cancel_rea_area%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF cancel_rea_area%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF cancel_rea_area%ROWTYPE;
    TYPE vat IS VARRAY(100) OF cancel_rea_area%ROWTYPE;

    -- Column Collection based on column "ID_CANCEL_REA_AREA"
    TYPE id_cancel_rea_area_cc IS TABLE OF cancel_rea_area.id_cancel_rea_area%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "INTERN_NAME"
    TYPE intern_name_cc IS TABLE OF cancel_rea_area.intern_name%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_cancel_rea_area_in IN cancel_rea_area.id_cancel_rea_area%TYPE,
        intern_name_in        IN cancel_rea_area.intern_name%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_cancel_rea_area_in IN cancel_rea_area.id_cancel_rea_area%TYPE,
        intern_name_in        IN cancel_rea_area.intern_name%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    PROCEDURE ins
    (
        rec_in          IN cancel_rea_area%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN cancel_rea_area%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN cancel_rea_area_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN cancel_rea_area_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        id_cancel_rea_area_in IN cancel_rea_area.id_cancel_rea_area%TYPE,
        intern_name_in        IN cancel_rea_area.intern_name%TYPE DEFAULT NULL,
        intern_name_nin       IN BOOLEAN := TRUE,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_cancel_rea_area_in IN cancel_rea_area.id_cancel_rea_area%TYPE,
        intern_name_in        IN cancel_rea_area.intern_name%TYPE DEFAULT NULL,
        intern_name_nin       IN BOOLEAN := TRUE,
        handle_error_in       IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        intern_name_in  IN cancel_rea_area.intern_name%TYPE DEFAULT NULL,
        intern_name_nin IN BOOLEAN := TRUE,
        where_in        VARCHAR2 DEFAULT NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        intern_name_in  IN cancel_rea_area.intern_name%TYPE DEFAULT NULL,
        intern_name_nin IN BOOLEAN := TRUE,
        where_in        VARCHAR2 DEFAULT NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_cancel_rea_area_in IN cancel_rea_area.id_cancel_rea_area%TYPE,
        intern_name_in        IN cancel_rea_area.intern_name%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_cancel_rea_area_in IN cancel_rea_area.id_cancel_rea_area%TYPE,
        intern_name_in        IN cancel_rea_area.intern_name%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN cancel_rea_area%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN cancel_rea_area%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN cancel_rea_area_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN cancel_rea_area_tc,
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
        id_cancel_rea_area_in IN cancel_rea_area.id_cancel_rea_area%TYPE,
        handle_error_in       IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_cancel_rea_area_in IN cancel_rea_area.id_cancel_rea_area%TYPE,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
    );

    -- Delete all rows for primary key column ID_CANCEL_REA_AREA
    PROCEDURE del_id_cancel_rea_area
    (
        id_cancel_rea_area_in IN cancel_rea_area.id_cancel_rea_area%TYPE,
        handle_error_in       IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_CANCEL_REA_AREA
    PROCEDURE del_id_cancel_rea_area
    (
        id_cancel_rea_area_in IN cancel_rea_area.id_cancel_rea_area%TYPE,
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
    PROCEDURE initrec(cancel_rea_area_inout IN OUT cancel_rea_area%ROWTYPE);

    FUNCTION initrec RETURN cancel_rea_area%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN cancel_rea_area_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN cancel_rea_area_tc;

END ts_cancel_rea_area;
/
