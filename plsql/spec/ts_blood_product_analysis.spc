/*-- Last Change Revision: $Rev: 2029086 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:42 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE ts_blood_product_analysis
/*
| Generated by or retrieved - DO NOT MODIFY!
| Created On: 2019-02-07 17:11:55
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on blood_product_analysis
    TYPE blood_product_analysis_tc IS TABLE OF blood_product_analysis%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE blood_product_analysis_ntt IS TABLE OF blood_product_analysis%ROWTYPE;
    TYPE blood_product_analysis_vat IS VARRAY(100) OF blood_product_analysis%ROWTYPE;

    -- Column Collection based on column ID_BLOOD_PRODUCT_ANALYSIS
    TYPE id_blood_product_analysis_cc IS TABLE OF blood_product_analysis.id_blood_product_analysis%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_BLOOD_PRODUCT_DET
    TYPE id_blood_product_det_cc IS TABLE OF blood_product_analysis.id_blood_product_det%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_ANALYSIS_REQ_DET
    TYPE id_analysis_req_det_cc IS TABLE OF blood_product_analysis.id_analysis_req_det%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_USER
    TYPE create_user_cc IS TABLE OF blood_product_analysis.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_TIME
    TYPE create_time_cc IS TABLE OF blood_product_analysis.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_INSTITUTION
    TYPE create_institution_cc IS TABLE OF blood_product_analysis.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_USER
    TYPE update_user_cc IS TABLE OF blood_product_analysis.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_TIME
    TYPE update_time_cc IS TABLE OF blood_product_analysis.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_INSTITUTION
    TYPE update_institution_cc IS TABLE OF blood_product_analysis.update_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_BLOOD_PRODUCT_EXECUTION
    TYPE id_blood_product_execution_cc IS TABLE OF blood_product_analysis.id_blood_product_execution%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present (with rows_out)
    PROCEDURE ins
    (
        id_blood_product_analysis_in  IN blood_product_analysis.id_blood_product_analysis%TYPE,
        id_blood_product_det_in       IN blood_product_analysis.id_blood_product_det%TYPE DEFAULT NULL,
        id_analysis_req_det_in        IN blood_product_analysis.id_analysis_req_det%TYPE DEFAULT NULL,
        create_user_in                IN blood_product_analysis.create_user%TYPE DEFAULT NULL,
        create_time_in                IN blood_product_analysis.create_time%TYPE DEFAULT NULL,
        create_institution_in         IN blood_product_analysis.create_institution%TYPE DEFAULT NULL,
        update_user_in                IN blood_product_analysis.update_user%TYPE DEFAULT NULL,
        update_time_in                IN blood_product_analysis.update_time%TYPE DEFAULT NULL,
        update_institution_in         IN blood_product_analysis.update_institution%TYPE DEFAULT NULL,
        id_blood_product_execution_in IN blood_product_analysis.id_blood_product_execution%TYPE DEFAULT NULL,
        handle_error_in               IN BOOLEAN := TRUE,
        rows_out                      OUT table_varchar
    );

    -- Insert one row, providing primary key if present (without rows_out)
    PROCEDURE ins
    (
        id_blood_product_analysis_in  IN blood_product_analysis.id_blood_product_analysis%TYPE,
        id_blood_product_det_in       IN blood_product_analysis.id_blood_product_det%TYPE DEFAULT NULL,
        id_analysis_req_det_in        IN blood_product_analysis.id_analysis_req_det%TYPE DEFAULT NULL,
        create_user_in                IN blood_product_analysis.create_user%TYPE DEFAULT NULL,
        create_time_in                IN blood_product_analysis.create_time%TYPE DEFAULT NULL,
        create_institution_in         IN blood_product_analysis.create_institution%TYPE DEFAULT NULL,
        update_user_in                IN blood_product_analysis.update_user%TYPE DEFAULT NULL,
        update_time_in                IN blood_product_analysis.update_time%TYPE DEFAULT NULL,
        update_institution_in         IN blood_product_analysis.update_institution%TYPE DEFAULT NULL,
        id_blood_product_execution_in IN blood_product_analysis.id_blood_product_execution%TYPE DEFAULT NULL,
        handle_error_in               IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record
    -- Specify whether or not a primary key value should be generated
    PROCEDURE ins
    (
        rec_in          IN blood_product_analysis%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert a row based on a record
    -- Specify whether or not a primary key value should be generated
    PROCEDURE ins
    (
        rec_in          IN blood_product_analysis%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers
    PROCEDURE ins
    (
        rows_in         IN blood_product_analysis_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers
    PROCEDURE ins
    (
        rows_in         IN blood_product_analysis_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Return next primary key value using the named sequence
    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN blood_product_analysis.id_blood_product_analysis%TYPE;

    -- Insert one row, generating hidden primary key using a sequence
    PROCEDURE ins
    (
        id_blood_product_det_in       IN blood_product_analysis.id_blood_product_det%TYPE DEFAULT NULL,
        id_analysis_req_det_in        IN blood_product_analysis.id_analysis_req_det%TYPE DEFAULT NULL,
        create_user_in                IN blood_product_analysis.create_user%TYPE DEFAULT NULL,
        create_time_in                IN blood_product_analysis.create_time%TYPE DEFAULT NULL,
        create_institution_in         IN blood_product_analysis.create_institution%TYPE DEFAULT NULL,
        update_user_in                IN blood_product_analysis.update_user%TYPE DEFAULT NULL,
        update_time_in                IN blood_product_analysis.update_time%TYPE DEFAULT NULL,
        update_institution_in         IN blood_product_analysis.update_institution%TYPE DEFAULT NULL,
        id_blood_product_execution_in IN blood_product_analysis.id_blood_product_execution%TYPE DEFAULT NULL,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert one row, generating hidden primary key using a sequence
    PROCEDURE ins
    (
        id_blood_product_det_in       IN blood_product_analysis.id_blood_product_det%TYPE DEFAULT NULL,
        id_analysis_req_det_in        IN blood_product_analysis.id_analysis_req_det%TYPE DEFAULT NULL,
        create_user_in                IN blood_product_analysis.create_user%TYPE DEFAULT NULL,
        create_time_in                IN blood_product_analysis.create_time%TYPE DEFAULT NULL,
        create_institution_in         IN blood_product_analysis.create_institution%TYPE DEFAULT NULL,
        update_user_in                IN blood_product_analysis.update_user%TYPE DEFAULT NULL,
        update_time_in                IN blood_product_analysis.update_time%TYPE DEFAULT NULL,
        update_institution_in         IN blood_product_analysis.update_institution%TYPE DEFAULT NULL,
        id_blood_product_execution_in IN blood_product_analysis.id_blood_product_execution%TYPE DEFAULT NULL,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row, returning primary key generated by sequence
    PROCEDURE ins
    (
        id_blood_product_det_in       IN blood_product_analysis.id_blood_product_det%TYPE DEFAULT NULL,
        id_analysis_req_det_in        IN blood_product_analysis.id_analysis_req_det%TYPE DEFAULT NULL,
        create_user_in                IN blood_product_analysis.create_user%TYPE DEFAULT NULL,
        create_time_in                IN blood_product_analysis.create_time%TYPE DEFAULT NULL,
        create_institution_in         IN blood_product_analysis.create_institution%TYPE DEFAULT NULL,
        update_user_in                IN blood_product_analysis.update_user%TYPE DEFAULT NULL,
        update_time_in                IN blood_product_analysis.update_time%TYPE DEFAULT NULL,
        update_institution_in         IN blood_product_analysis.update_institution%TYPE DEFAULT NULL,
        id_blood_product_execution_in IN blood_product_analysis.id_blood_product_execution%TYPE DEFAULT NULL,
        id_blood_product_analysis_out IN OUT blood_product_analysis.id_blood_product_analysis%TYPE,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert one row, returning primary key generated by sequence
    PROCEDURE ins
    (
        id_blood_product_det_in       IN blood_product_analysis.id_blood_product_det%TYPE DEFAULT NULL,
        id_analysis_req_det_in        IN blood_product_analysis.id_analysis_req_det%TYPE DEFAULT NULL,
        create_user_in                IN blood_product_analysis.create_user%TYPE DEFAULT NULL,
        create_time_in                IN blood_product_analysis.create_time%TYPE DEFAULT NULL,
        create_institution_in         IN blood_product_analysis.create_institution%TYPE DEFAULT NULL,
        update_user_in                IN blood_product_analysis.update_user%TYPE DEFAULT NULL,
        update_time_in                IN blood_product_analysis.update_time%TYPE DEFAULT NULL,
        update_institution_in         IN blood_product_analysis.update_institution%TYPE DEFAULT NULL,
        id_blood_product_execution_in IN blood_product_analysis.id_blood_product_execution%TYPE DEFAULT NULL,
        id_blood_product_analysis_out IN OUT blood_product_analysis.id_blood_product_analysis%TYPE,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row with function, return generated primary key
    FUNCTION ins
    (
        id_blood_product_det_in       IN blood_product_analysis.id_blood_product_det%TYPE DEFAULT NULL,
        id_analysis_req_det_in        IN blood_product_analysis.id_analysis_req_det%TYPE DEFAULT NULL,
        create_user_in                IN blood_product_analysis.create_user%TYPE DEFAULT NULL,
        create_time_in                IN blood_product_analysis.create_time%TYPE DEFAULT NULL,
        create_institution_in         IN blood_product_analysis.create_institution%TYPE DEFAULT NULL,
        update_user_in                IN blood_product_analysis.update_user%TYPE DEFAULT NULL,
        update_time_in                IN blood_product_analysis.update_time%TYPE DEFAULT NULL,
        update_institution_in         IN blood_product_analysis.update_institution%TYPE DEFAULT NULL,
        id_blood_product_execution_in IN blood_product_analysis.id_blood_product_execution%TYPE DEFAULT NULL,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    ) RETURN blood_product_analysis.id_blood_product_analysis%TYPE;

    -- Insert one row with function, return generated primary key
    FUNCTION ins
    (
        id_blood_product_det_in       IN blood_product_analysis.id_blood_product_det%TYPE DEFAULT NULL,
        id_analysis_req_det_in        IN blood_product_analysis.id_analysis_req_det%TYPE DEFAULT NULL,
        create_user_in                IN blood_product_analysis.create_user%TYPE DEFAULT NULL,
        create_time_in                IN blood_product_analysis.create_time%TYPE DEFAULT NULL,
        create_institution_in         IN blood_product_analysis.create_institution%TYPE DEFAULT NULL,
        update_user_in                IN blood_product_analysis.update_user%TYPE DEFAULT NULL,
        update_time_in                IN blood_product_analysis.update_time%TYPE DEFAULT NULL,
        update_institution_in         IN blood_product_analysis.update_institution%TYPE DEFAULT NULL,
        id_blood_product_execution_in IN blood_product_analysis.id_blood_product_execution%TYPE DEFAULT NULL,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE
    ) RETURN blood_product_analysis.id_blood_product_analysis%TYPE;

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.
    PROCEDURE upd
    (
        id_blood_product_analysis_in   IN blood_product_analysis.id_blood_product_analysis%TYPE,
        id_blood_product_det_in        IN blood_product_analysis.id_blood_product_det%TYPE DEFAULT NULL,
        id_blood_product_det_nin       IN BOOLEAN := TRUE,
        id_analysis_req_det_in         IN blood_product_analysis.id_analysis_req_det%TYPE DEFAULT NULL,
        id_analysis_req_det_nin        IN BOOLEAN := TRUE,
        create_user_in                 IN blood_product_analysis.create_user%TYPE DEFAULT NULL,
        create_user_nin                IN BOOLEAN := TRUE,
        create_time_in                 IN blood_product_analysis.create_time%TYPE DEFAULT NULL,
        create_time_nin                IN BOOLEAN := TRUE,
        create_institution_in          IN blood_product_analysis.create_institution%TYPE DEFAULT NULL,
        create_institution_nin         IN BOOLEAN := TRUE,
        update_user_in                 IN blood_product_analysis.update_user%TYPE DEFAULT NULL,
        update_user_nin                IN BOOLEAN := TRUE,
        update_time_in                 IN blood_product_analysis.update_time%TYPE DEFAULT NULL,
        update_time_nin                IN BOOLEAN := TRUE,
        update_institution_in          IN blood_product_analysis.update_institution%TYPE DEFAULT NULL,
        update_institution_nin         IN BOOLEAN := TRUE,
        id_blood_product_execution_in  IN blood_product_analysis.id_blood_product_execution%TYPE DEFAULT NULL,
        id_blood_product_execution_nin IN BOOLEAN := TRUE,
        handle_error_in                IN BOOLEAN := TRUE,
        rows_out                       IN OUT table_varchar
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.
    PROCEDURE upd
    (
        id_blood_product_analysis_in   IN blood_product_analysis.id_blood_product_analysis%TYPE,
        id_blood_product_det_in        IN blood_product_analysis.id_blood_product_det%TYPE DEFAULT NULL,
        id_blood_product_det_nin       IN BOOLEAN := TRUE,
        id_analysis_req_det_in         IN blood_product_analysis.id_analysis_req_det%TYPE DEFAULT NULL,
        id_analysis_req_det_nin        IN BOOLEAN := TRUE,
        create_user_in                 IN blood_product_analysis.create_user%TYPE DEFAULT NULL,
        create_user_nin                IN BOOLEAN := TRUE,
        create_time_in                 IN blood_product_analysis.create_time%TYPE DEFAULT NULL,
        create_time_nin                IN BOOLEAN := TRUE,
        create_institution_in          IN blood_product_analysis.create_institution%TYPE DEFAULT NULL,
        create_institution_nin         IN BOOLEAN := TRUE,
        update_user_in                 IN blood_product_analysis.update_user%TYPE DEFAULT NULL,
        update_user_nin                IN BOOLEAN := TRUE,
        update_time_in                 IN blood_product_analysis.update_time%TYPE DEFAULT NULL,
        update_time_nin                IN BOOLEAN := TRUE,
        update_institution_in          IN blood_product_analysis.update_institution%TYPE DEFAULT NULL,
        update_institution_nin         IN BOOLEAN := TRUE,
        id_blood_product_execution_in  IN blood_product_analysis.id_blood_product_execution%TYPE DEFAULT NULL,
        id_blood_product_execution_nin IN BOOLEAN := TRUE,
        handle_error_in                IN BOOLEAN := TRUE
    );

    --Update any/all columns by dynamic WHERE
    -- If you pass NULL, then the current column value is set to itself
    PROCEDURE upd
    (
        id_blood_product_det_in        IN blood_product_analysis.id_blood_product_det%TYPE DEFAULT NULL,
        id_blood_product_det_nin       IN BOOLEAN := TRUE,
        id_analysis_req_det_in         IN blood_product_analysis.id_analysis_req_det%TYPE DEFAULT NULL,
        id_analysis_req_det_nin        IN BOOLEAN := TRUE,
        create_user_in                 IN blood_product_analysis.create_user%TYPE DEFAULT NULL,
        create_user_nin                IN BOOLEAN := TRUE,
        create_time_in                 IN blood_product_analysis.create_time%TYPE DEFAULT NULL,
        create_time_nin                IN BOOLEAN := TRUE,
        create_institution_in          IN blood_product_analysis.create_institution%TYPE DEFAULT NULL,
        create_institution_nin         IN BOOLEAN := TRUE,
        update_user_in                 IN blood_product_analysis.update_user%TYPE DEFAULT NULL,
        update_user_nin                IN BOOLEAN := TRUE,
        update_time_in                 IN blood_product_analysis.update_time%TYPE DEFAULT NULL,
        update_time_nin                IN BOOLEAN := TRUE,
        update_institution_in          IN blood_product_analysis.update_institution%TYPE DEFAULT NULL,
        update_institution_nin         IN BOOLEAN := TRUE,
        id_blood_product_execution_in  IN blood_product_analysis.id_blood_product_execution%TYPE DEFAULT NULL,
        id_blood_product_execution_nin IN BOOLEAN := TRUE,
        where_in                       IN VARCHAR2,
        handle_error_in                IN BOOLEAN := TRUE,
        rows_out                       IN OUT table_varchar
    );

    --Update any/all columns by dynamic WHERE
    -- If you pass NULL, then the current column value is set to itself
    PROCEDURE upd
    (
        id_blood_product_det_in        IN blood_product_analysis.id_blood_product_det%TYPE DEFAULT NULL,
        id_blood_product_det_nin       IN BOOLEAN := TRUE,
        id_analysis_req_det_in         IN blood_product_analysis.id_analysis_req_det%TYPE DEFAULT NULL,
        id_analysis_req_det_nin        IN BOOLEAN := TRUE,
        create_user_in                 IN blood_product_analysis.create_user%TYPE DEFAULT NULL,
        create_user_nin                IN BOOLEAN := TRUE,
        create_time_in                 IN blood_product_analysis.create_time%TYPE DEFAULT NULL,
        create_time_nin                IN BOOLEAN := TRUE,
        create_institution_in          IN blood_product_analysis.create_institution%TYPE DEFAULT NULL,
        create_institution_nin         IN BOOLEAN := TRUE,
        update_user_in                 IN blood_product_analysis.update_user%TYPE DEFAULT NULL,
        update_user_nin                IN BOOLEAN := TRUE,
        update_time_in                 IN blood_product_analysis.update_time%TYPE DEFAULT NULL,
        update_time_nin                IN BOOLEAN := TRUE,
        update_institution_in          IN blood_product_analysis.update_institution%TYPE DEFAULT NULL,
        update_institution_nin         IN BOOLEAN := TRUE,
        id_blood_product_execution_in  IN blood_product_analysis.id_blood_product_execution%TYPE DEFAULT NULL,
        id_blood_product_execution_nin IN BOOLEAN := TRUE,
        where_in                       IN VARCHAR2,
        handle_error_in                IN BOOLEAN := TRUE
    );

    --Update/insert with columns (with rows_out)
    PROCEDURE upd_ins
    (
        id_blood_product_analysis_in  IN blood_product_analysis.id_blood_product_analysis%TYPE,
        id_blood_product_det_in       IN blood_product_analysis.id_blood_product_det%TYPE DEFAULT NULL,
        id_analysis_req_det_in        IN blood_product_analysis.id_analysis_req_det%TYPE DEFAULT NULL,
        create_user_in                IN blood_product_analysis.create_user%TYPE DEFAULT NULL,
        create_time_in                IN blood_product_analysis.create_time%TYPE DEFAULT NULL,
        create_institution_in         IN blood_product_analysis.create_institution%TYPE DEFAULT NULL,
        update_user_in                IN blood_product_analysis.update_user%TYPE DEFAULT NULL,
        update_time_in                IN blood_product_analysis.update_time%TYPE DEFAULT NULL,
        update_institution_in         IN blood_product_analysis.update_institution%TYPE DEFAULT NULL,
        id_blood_product_execution_in IN blood_product_analysis.id_blood_product_execution%TYPE DEFAULT NULL,
        handle_error_in               IN BOOLEAN := TRUE,
        rows_out                      IN OUT table_varchar
    );

    --Update/insert with columns (without rows_out)
    PROCEDURE upd_ins
    (
        id_blood_product_analysis_in  IN blood_product_analysis.id_blood_product_analysis%TYPE,
        id_blood_product_det_in       IN blood_product_analysis.id_blood_product_det%TYPE DEFAULT NULL,
        id_analysis_req_det_in        IN blood_product_analysis.id_analysis_req_det%TYPE DEFAULT NULL,
        create_user_in                IN blood_product_analysis.create_user%TYPE DEFAULT NULL,
        create_time_in                IN blood_product_analysis.create_time%TYPE DEFAULT NULL,
        create_institution_in         IN blood_product_analysis.create_institution%TYPE DEFAULT NULL,
        update_user_in                IN blood_product_analysis.update_user%TYPE DEFAULT NULL,
        update_time_in                IN blood_product_analysis.update_time%TYPE DEFAULT NULL,
        update_institution_in         IN blood_product_analysis.update_institution%TYPE DEFAULT NULL,
        id_blood_product_execution_in IN blood_product_analysis.id_blood_product_execution%TYPE DEFAULT NULL,
        handle_error_in               IN BOOLEAN := TRUE
    );

    --Update record (with rows_out)
    PROCEDURE upd
    (
        rec_in          IN blood_product_analysis%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    --Update record (without rows_out)
    PROCEDURE upd
    (
        rec_in          IN blood_product_analysis%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    --Update collection (with rows_out)
    PROCEDURE upd
    (
        col_in            IN blood_product_analysis_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    --Update collection (without rows_out)
    PROCEDURE upd
    (
        col_in            IN blood_product_analysis_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Use Native Dynamic SQL increment a single NUMBER column
    -- for all rows specified by the dynamic WHERE clause
    PROCEDURE increment_onecol
    (
        colname_in         IN all_tab_columns.column_name%TYPE,
        where_in           IN VARCHAR2,
        increment_value_in IN NUMBER DEFAULT 1,
        handle_error_in    IN BOOLEAN := TRUE,
        rows_out           OUT table_varchar
    );

    --increment column value
    PROCEDURE increment_onecol
    (
        colname_in         IN all_tab_columns.column_name%TYPE,
        where_in           IN VARCHAR2,
        increment_value_in IN NUMBER DEFAULT 1,
        handle_error_in    IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_blood_product_analysis_in IN blood_product_analysis.id_blood_product_analysis%TYPE,
        handle_error_in              IN BOOLEAN := TRUE,
        rows_out                     OUT table_varchar
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_blood_product_analysis_in IN blood_product_analysis.id_blood_product_analysis%TYPE,
        handle_error_in              IN BOOLEAN := TRUE
    );

    -- Delete all rows specified by dynamic WHERE clause
    PROCEDURE del_by
    (
        where_clause_in IN VARCHAR2,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows specified by dynamic WHERE clause
    PROCEDURE del_by
    (
        where_clause_in IN VARCHAR2,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this BPA_AR_FK foreign key value
    PROCEDURE del_bpa_ar_fk
    (
        id_analysis_req_det_in IN blood_product_analysis.id_analysis_req_det%TYPE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               OUT table_varchar
    );

    -- Delete all rows for this BPA_BPD_FK foreign key value
    PROCEDURE del_bpa_bpd_fk
    (
        id_blood_product_det_in IN blood_product_analysis.id_blood_product_det%TYPE,
        handle_error_in         IN BOOLEAN := TRUE,
        rows_out                OUT table_varchar
    );

    -- Delete all rows for this BPA_AR_FK foreign key value
    PROCEDURE del_bpa_ar_fk
    (
        id_analysis_req_det_in IN blood_product_analysis.id_analysis_req_det%TYPE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    -- Delete all rows for this BPA_BPD_FK foreign key value
    PROCEDURE del_bpa_bpd_fk
    (
        id_blood_product_det_in IN blood_product_analysis.id_blood_product_det%TYPE,
        handle_error_in         IN BOOLEAN := TRUE
    );

    -- Initialize a record with default values for columns in the table (prc)
    PROCEDURE initrec(blood_product_analysis_inout IN OUT blood_product_analysis%ROWTYPE);

    -- Initialize a record with default values for columns in the table (fnc)
    FUNCTION initrec RETURN blood_product_analysis%ROWTYPE;

    -- Get data rowid
    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN blood_product_analysis_tc;

    -- Get data rowid pragma autonomous transaccion
    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN blood_product_analysis_tc;

END ts_blood_product_analysis;
/
