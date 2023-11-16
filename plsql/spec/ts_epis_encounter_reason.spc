/*-- Last Change Revision: $Rev: 2029141 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:50:00 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE TS_EPIS_ENCOUNTER_REASON
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Agosto 20, 2009 9:32:13
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "EPIS_ENCOUNTER_REASON"
    TYPE epis_encounter_reason_tc IS TABLE OF epis_encounter_reason%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE epis_encounter_reason_ntt IS TABLE OF epis_encounter_reason%ROWTYPE;
    TYPE epis_encounter_reason_vat IS VARRAY(100) OF epis_encounter_reason%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF epis_encounter_reason%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF epis_encounter_reason%ROWTYPE;
    TYPE vat IS VARRAY(100) OF epis_encounter_reason%ROWTYPE;

    -- Column Collection based on column "ID_EPIS_ENCOUNTER"
    TYPE id_epis_encounter_cc IS TABLE OF epis_encounter_reason.id_epis_encounter%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_REASON"
    TYPE id_reason_cc IS TABLE OF epis_encounter_reason.id_reason%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_USER"
    TYPE create_user_cc IS TABLE OF epis_encounter_reason.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_TIME"
    TYPE create_time_cc IS TABLE OF epis_encounter_reason.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_INSTITUTION"
    TYPE create_institution_cc IS TABLE OF epis_encounter_reason.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_USER"
    TYPE update_user_cc IS TABLE OF epis_encounter_reason.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_TIME"
    TYPE update_time_cc IS TABLE OF epis_encounter_reason.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_INSTITUTION"
    TYPE update_institution_cc IS TABLE OF epis_encounter_reason.update_institution%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_epis_encounter_in  IN epis_encounter_reason.id_epis_encounter%TYPE,
        id_reason_in          IN epis_encounter_reason.id_reason%TYPE,
        create_user_in        IN epis_encounter_reason.create_user%TYPE DEFAULT NULL,
        create_time_in        IN epis_encounter_reason.create_time%TYPE DEFAULT NULL,
        create_institution_in IN epis_encounter_reason.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN epis_encounter_reason.update_user%TYPE DEFAULT NULL,
        update_time_in        IN epis_encounter_reason.update_time%TYPE DEFAULT NULL,
        update_institution_in IN epis_encounter_reason.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_epis_encounter_in  IN epis_encounter_reason.id_epis_encounter%TYPE,
        id_reason_in          IN epis_encounter_reason.id_reason%TYPE,
        create_user_in        IN epis_encounter_reason.create_user%TYPE DEFAULT NULL,
        create_time_in        IN epis_encounter_reason.create_time%TYPE DEFAULT NULL,
        create_institution_in IN epis_encounter_reason.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN epis_encounter_reason.update_user%TYPE DEFAULT NULL,
        update_time_in        IN epis_encounter_reason.update_time%TYPE DEFAULT NULL,
        update_institution_in IN epis_encounter_reason.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    PROCEDURE ins
    (
        rec_in          IN epis_encounter_reason%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN epis_encounter_reason%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN epis_encounter_reason_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN epis_encounter_reason_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        id_epis_encounter_in   IN epis_encounter_reason.id_epis_encounter%TYPE,
        id_reason_in           IN epis_encounter_reason.id_reason%TYPE,
        create_user_in         IN epis_encounter_reason.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN epis_encounter_reason.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN epis_encounter_reason.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN epis_encounter_reason.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN epis_encounter_reason.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN epis_encounter_reason.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_epis_encounter_in   IN epis_encounter_reason.id_epis_encounter%TYPE,
        id_reason_in           IN epis_encounter_reason.id_reason%TYPE,
        create_user_in         IN epis_encounter_reason.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN epis_encounter_reason.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN epis_encounter_reason.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN epis_encounter_reason.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN epis_encounter_reason.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN epis_encounter_reason.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        create_user_in         IN epis_encounter_reason.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN epis_encounter_reason.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN epis_encounter_reason.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN epis_encounter_reason.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN epis_encounter_reason.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN epis_encounter_reason.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        where_in               VARCHAR2 DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    PROCEDURE upd
    (
        create_user_in         IN epis_encounter_reason.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN epis_encounter_reason.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN epis_encounter_reason.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN epis_encounter_reason.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN epis_encounter_reason.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN epis_encounter_reason.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        where_in               VARCHAR2 DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_epis_encounter_in  IN epis_encounter_reason.id_epis_encounter%TYPE,
        id_reason_in          IN epis_encounter_reason.id_reason%TYPE,
        create_user_in        IN epis_encounter_reason.create_user%TYPE DEFAULT NULL,
        create_time_in        IN epis_encounter_reason.create_time%TYPE DEFAULT NULL,
        create_institution_in IN epis_encounter_reason.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN epis_encounter_reason.update_user%TYPE DEFAULT NULL,
        update_time_in        IN epis_encounter_reason.update_time%TYPE DEFAULT NULL,
        update_institution_in IN epis_encounter_reason.update_institution%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_epis_encounter_in  IN epis_encounter_reason.id_epis_encounter%TYPE,
        id_reason_in          IN epis_encounter_reason.id_reason%TYPE,
        create_user_in        IN epis_encounter_reason.create_user%TYPE DEFAULT NULL,
        create_time_in        IN epis_encounter_reason.create_time%TYPE DEFAULT NULL,
        create_institution_in IN epis_encounter_reason.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN epis_encounter_reason.update_user%TYPE DEFAULT NULL,
        update_time_in        IN epis_encounter_reason.update_time%TYPE DEFAULT NULL,
        update_institution_in IN epis_encounter_reason.update_institution%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN epis_encounter_reason%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN epis_encounter_reason%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN epis_encounter_reason_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN epis_encounter_reason_tc,
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
        id_epis_encounter_in IN epis_encounter_reason.id_epis_encounter%TYPE,
        id_reason_in         IN epis_encounter_reason.id_reason%TYPE,
        handle_error_in      IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_epis_encounter_in IN epis_encounter_reason.id_epis_encounter%TYPE,
        id_reason_in         IN epis_encounter_reason.id_reason%TYPE,
        handle_error_in      IN BOOLEAN := TRUE,
        rows_out             OUT table_varchar
    );

    -- Delete all rows for primary key column ID_EPIS_ENCOUNTER
    PROCEDURE del_id_epis_encounter
    (
        id_epis_encounter_in IN epis_encounter_reason.id_epis_encounter%TYPE,
        handle_error_in      IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_EPIS_ENCOUNTER
    PROCEDURE del_id_epis_encounter
    (
        id_epis_encounter_in IN epis_encounter_reason.id_epis_encounter%TYPE,
        handle_error_in      IN BOOLEAN := TRUE,
        rows_out             OUT table_varchar
    );

    -- Delete all rows for primary key column ID_REASON
    PROCEDURE del_id_reason
    (
        id_reason_in    IN epis_encounter_reason.id_reason%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_REASON
    PROCEDURE del_id_reason
    (
        id_reason_in    IN epis_encounter_reason.id_reason%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this ECR_EC_FK foreign key value
    PROCEDURE del_ecr_ec_fk
    (
        id_epis_encounter_in IN epis_encounter_reason.id_epis_encounter%TYPE,
        handle_error_in      IN BOOLEAN := TRUE
    );

    -- Delete all rows for this ECR_EC_FK foreign key value
    PROCEDURE del_ecr_ec_fk
    (
        id_epis_encounter_in IN epis_encounter_reason.id_epis_encounter%TYPE,
        handle_error_in      IN BOOLEAN := TRUE,
        rows_out             OUT table_varchar
    );

    -- Delete all rows for this ECR_RE_FK foreign key value
    PROCEDURE del_ecr_re_fk
    (
        id_reason_in    IN epis_encounter_reason.id_reason%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this ECR_RE_FK foreign key value
    PROCEDURE del_ecr_re_fk
    (
        id_reason_in    IN epis_encounter_reason.id_reason%TYPE,
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
    PROCEDURE initrec(epis_encounter_reason_inout IN OUT epis_encounter_reason%ROWTYPE);

    FUNCTION initrec RETURN epis_encounter_reason%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN epis_encounter_reason_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN epis_encounter_reason_tc;

END ts_epis_encounter_reason;

 
/
