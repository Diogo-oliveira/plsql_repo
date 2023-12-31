/*-- Last Change Revision: $Rev: 1307034 $*/
/*-- Last Change by: $Author: ana.monteiro $*/
/*-- Date of last change: $Date: 2012-05-22 09:10:44 +0100 (ter, 22 mai 2012) $*/
CREATE OR REPLACE PACKAGE ts_pat_rcm_det
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: April 26, 2012 11:15:16
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "PAT_RCM_DET"
    TYPE pat_rcm_det_tc IS TABLE OF pat_rcm_det%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE pat_rcm_det_ntt IS TABLE OF pat_rcm_det%ROWTYPE;
    TYPE pat_rcm_det_vat IS VARRAY(100) OF pat_rcm_det%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF pat_rcm_det%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF pat_rcm_det%ROWTYPE;
    TYPE vat IS VARRAY(100) OF pat_rcm_det%ROWTYPE;

    -- Column Collection based on column "ID_PATIENT"
    TYPE id_patient_cc IS TABLE OF pat_rcm_det.id_patient%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_RCM"
    TYPE id_rcm_cc IS TABLE OF pat_rcm_det.id_rcm%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_RCM_DET"
    TYPE id_rcm_det_cc IS TABLE OF pat_rcm_det.id_rcm_det%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_RCM_ORIG"
    TYPE id_rcm_orig_cc IS TABLE OF pat_rcm_det.id_rcm_orig%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_RCM_ORIG_VALUE"
    TYPE id_rcm_orig_value_cc IS TABLE OF pat_rcm_det.id_rcm_orig_value%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_USER"
    TYPE create_user_cc IS TABLE OF pat_rcm_det.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_TIME"
    TYPE create_time_cc IS TABLE OF pat_rcm_det.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_INSTITUTION"
    TYPE create_institution_cc IS TABLE OF pat_rcm_det.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_USER"
    TYPE update_user_cc IS TABLE OF pat_rcm_det.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_TIME"
    TYPE update_time_cc IS TABLE OF pat_rcm_det.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_INSTITUTION"
    TYPE update_institution_cc IS TABLE OF pat_rcm_det.update_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "RCM_TEXT"
    TYPE rcm_text_cc IS TABLE OF pat_rcm_det.rcm_text%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_CREATE"
    TYPE dt_create_cc IS TABLE OF pat_rcm_det.dt_create%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_INSTITUTION"
    TYPE id_institution_cc IS TABLE OF pat_rcm_det.id_institution%TYPE INDEX BY BINARY_INTEGER;

    TYPE varchar2_t IS TABLE OF VARCHAR2(32767) INDEX BY PLS_INTEGER;
    /*
    START Special logic for handling LOB columns....
    */
    PROCEDURE n_ins_clobs_in_chunks
    (
        id_patient_in         IN pat_rcm_det.id_patient%TYPE,
        id_institution_in     IN pat_rcm_det.id_institution%TYPE,
        id_rcm_in             IN pat_rcm_det.id_rcm%TYPE,
        id_rcm_det_in         IN pat_rcm_det.id_rcm_det%TYPE,
        id_rcm_orig_in        IN pat_rcm_det.id_rcm_orig%TYPE DEFAULT NULL,
        id_rcm_orig_value_in  IN pat_rcm_det.id_rcm_orig_value%TYPE DEFAULT NULL,
        create_user_in        IN pat_rcm_det.create_user%TYPE DEFAULT NULL,
        create_time_in        IN pat_rcm_det.create_time%TYPE DEFAULT NULL,
        create_institution_in IN pat_rcm_det.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN pat_rcm_det.update_user%TYPE DEFAULT NULL,
        update_time_in        IN pat_rcm_det.update_time%TYPE DEFAULT NULL,
        update_institution_in IN pat_rcm_det.update_institution%TYPE DEFAULT NULL,
        dt_create_in          IN pat_rcm_det.dt_create%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE,
        clob_columns_in       IN varchar2_t,
        clob_pieces_in        IN varchar2_t
    );

    PROCEDURE n_upd_clobs_in_chunks
    (
        id_patient_in         IN pat_rcm_det.id_patient%TYPE,
        id_institution_in     IN pat_rcm_det.id_institution%TYPE,
        id_rcm_in             IN pat_rcm_det.id_rcm%TYPE,
        id_rcm_det_in         IN pat_rcm_det.id_rcm_det%TYPE,
        id_rcm_orig_in        IN pat_rcm_det.id_rcm_orig%TYPE DEFAULT NULL,
        id_rcm_orig_value_in  IN pat_rcm_det.id_rcm_orig_value%TYPE DEFAULT NULL,
        create_user_in        IN pat_rcm_det.create_user%TYPE DEFAULT NULL,
        create_time_in        IN pat_rcm_det.create_time%TYPE DEFAULT NULL,
        create_institution_in IN pat_rcm_det.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN pat_rcm_det.update_user%TYPE DEFAULT NULL,
        update_time_in        IN pat_rcm_det.update_time%TYPE DEFAULT NULL,
        update_institution_in IN pat_rcm_det.update_institution%TYPE DEFAULT NULL,
        dt_create_in          IN pat_rcm_det.dt_create%TYPE DEFAULT NULL,
        ignore_if_null_in     IN BOOLEAN := TRUE,
        handle_error_in       IN BOOLEAN := TRUE,
        clob_columns_in       IN varchar2_t,
        clob_pieces_in        IN varchar2_t
    );

    PROCEDURE n_upd_ins_clobs_in_chunks
    (
        id_patient_in         IN pat_rcm_det.id_patient%TYPE,
        id_institution_in     IN pat_rcm_det.id_institution%TYPE,
        id_rcm_in             IN pat_rcm_det.id_rcm%TYPE,
        id_rcm_det_in         IN pat_rcm_det.id_rcm_det%TYPE,
        id_rcm_orig_in        IN pat_rcm_det.id_rcm_orig%TYPE DEFAULT NULL,
        id_rcm_orig_value_in  IN pat_rcm_det.id_rcm_orig_value%TYPE DEFAULT NULL,
        create_user_in        IN pat_rcm_det.create_user%TYPE DEFAULT NULL,
        create_time_in        IN pat_rcm_det.create_time%TYPE DEFAULT NULL,
        create_institution_in IN pat_rcm_det.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN pat_rcm_det.update_user%TYPE DEFAULT NULL,
        update_time_in        IN pat_rcm_det.update_time%TYPE DEFAULT NULL,
        update_institution_in IN pat_rcm_det.update_institution%TYPE DEFAULT NULL,
        dt_create_in          IN pat_rcm_det.dt_create%TYPE DEFAULT NULL,
        ignore_if_null_in     IN BOOLEAN DEFAULT TRUE,
        handle_error_in       IN BOOLEAN DEFAULT TRUE,
        clob_columns_in       IN varchar2_t,
        clob_pieces_in        IN varchar2_t
    );

    /*
    END Special logic for handling LOB columns.
    */
    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_patient_in         IN pat_rcm_det.id_patient%TYPE,
        id_institution_in     IN pat_rcm_det.id_institution%TYPE,
        id_rcm_in             IN pat_rcm_det.id_rcm%TYPE,
        id_rcm_det_in         IN pat_rcm_det.id_rcm_det%TYPE,
        id_rcm_orig_in        IN pat_rcm_det.id_rcm_orig%TYPE DEFAULT NULL,
        id_rcm_orig_value_in  IN pat_rcm_det.id_rcm_orig_value%TYPE DEFAULT NULL,
        create_user_in        IN pat_rcm_det.create_user%TYPE DEFAULT NULL,
        create_time_in        IN pat_rcm_det.create_time%TYPE DEFAULT NULL,
        create_institution_in IN pat_rcm_det.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN pat_rcm_det.update_user%TYPE DEFAULT NULL,
        update_time_in        IN pat_rcm_det.update_time%TYPE DEFAULT NULL,
        update_institution_in IN pat_rcm_det.update_institution%TYPE DEFAULT NULL,
        rcm_text_in           IN pat_rcm_det.rcm_text%TYPE DEFAULT NULL,
        dt_create_in          IN pat_rcm_det.dt_create%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_patient_in         IN pat_rcm_det.id_patient%TYPE,
        id_institution_in     IN pat_rcm_det.id_institution%TYPE,
        id_rcm_in             IN pat_rcm_det.id_rcm%TYPE,
        id_rcm_det_in         IN pat_rcm_det.id_rcm_det%TYPE,
        id_rcm_orig_in        IN pat_rcm_det.id_rcm_orig%TYPE DEFAULT NULL,
        id_rcm_orig_value_in  IN pat_rcm_det.id_rcm_orig_value%TYPE DEFAULT NULL,
        create_user_in        IN pat_rcm_det.create_user%TYPE DEFAULT NULL,
        create_time_in        IN pat_rcm_det.create_time%TYPE DEFAULT NULL,
        create_institution_in IN pat_rcm_det.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN pat_rcm_det.update_user%TYPE DEFAULT NULL,
        update_time_in        IN pat_rcm_det.update_time%TYPE DEFAULT NULL,
        update_institution_in IN pat_rcm_det.update_institution%TYPE DEFAULT NULL,
        rcm_text_in           IN pat_rcm_det.rcm_text%TYPE DEFAULT NULL,
        dt_create_in          IN pat_rcm_det.dt_create%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    PROCEDURE ins
    (
        rec_in          IN pat_rcm_det%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN pat_rcm_det%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN pat_rcm_det_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN pat_rcm_det_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        id_patient_in          IN pat_rcm_det.id_patient%TYPE,
        id_institution_in      IN pat_rcm_det.id_institution%TYPE,
        id_rcm_in              IN pat_rcm_det.id_rcm%TYPE,
        id_rcm_det_in          IN pat_rcm_det.id_rcm_det%TYPE,
        id_rcm_orig_in         IN pat_rcm_det.id_rcm_orig%TYPE DEFAULT NULL,
        id_rcm_orig_nin        IN BOOLEAN := TRUE,
        id_rcm_orig_value_in   IN pat_rcm_det.id_rcm_orig_value%TYPE DEFAULT NULL,
        id_rcm_orig_value_nin  IN BOOLEAN := TRUE,
        create_user_in         IN pat_rcm_det.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN pat_rcm_det.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN pat_rcm_det.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN pat_rcm_det.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN pat_rcm_det.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN pat_rcm_det.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        rcm_text_in            IN pat_rcm_det.rcm_text%TYPE DEFAULT NULL,
        rcm_text_nin           IN BOOLEAN := TRUE,
        dt_create_in           IN pat_rcm_det.dt_create%TYPE DEFAULT NULL,
        dt_create_nin          IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_patient_in          IN pat_rcm_det.id_patient%TYPE,
        id_institution_in      IN pat_rcm_det.id_institution%TYPE,
        id_rcm_in              IN pat_rcm_det.id_rcm%TYPE,
        id_rcm_det_in          IN pat_rcm_det.id_rcm_det%TYPE,
        id_rcm_orig_in         IN pat_rcm_det.id_rcm_orig%TYPE DEFAULT NULL,
        id_rcm_orig_nin        IN BOOLEAN := TRUE,
        id_rcm_orig_value_in   IN pat_rcm_det.id_rcm_orig_value%TYPE DEFAULT NULL,
        id_rcm_orig_value_nin  IN BOOLEAN := TRUE,
        create_user_in         IN pat_rcm_det.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN pat_rcm_det.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN pat_rcm_det.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN pat_rcm_det.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN pat_rcm_det.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN pat_rcm_det.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        rcm_text_in            IN pat_rcm_det.rcm_text%TYPE DEFAULT NULL,
        rcm_text_nin           IN BOOLEAN := TRUE,
        dt_create_in           IN pat_rcm_det.dt_create%TYPE DEFAULT NULL,
        dt_create_nin          IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        id_rcm_orig_in         IN pat_rcm_det.id_rcm_orig%TYPE DEFAULT NULL,
        id_rcm_orig_nin        IN BOOLEAN := TRUE,
        id_rcm_orig_value_in   IN pat_rcm_det.id_rcm_orig_value%TYPE DEFAULT NULL,
        id_rcm_orig_value_nin  IN BOOLEAN := TRUE,
        create_user_in         IN pat_rcm_det.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN pat_rcm_det.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN pat_rcm_det.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN pat_rcm_det.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN pat_rcm_det.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN pat_rcm_det.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        rcm_text_in            IN pat_rcm_det.rcm_text%TYPE DEFAULT NULL,
        rcm_text_nin           IN BOOLEAN := TRUE,
        dt_create_in           IN pat_rcm_det.dt_create%TYPE DEFAULT NULL,
        dt_create_nin          IN BOOLEAN := TRUE,
        where_in               VARCHAR2,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_rcm_orig_in         IN pat_rcm_det.id_rcm_orig%TYPE DEFAULT NULL,
        id_rcm_orig_nin        IN BOOLEAN := TRUE,
        id_rcm_orig_value_in   IN pat_rcm_det.id_rcm_orig_value%TYPE DEFAULT NULL,
        id_rcm_orig_value_nin  IN BOOLEAN := TRUE,
        create_user_in         IN pat_rcm_det.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN pat_rcm_det.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN pat_rcm_det.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN pat_rcm_det.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN pat_rcm_det.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN pat_rcm_det.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        rcm_text_in            IN pat_rcm_det.rcm_text%TYPE DEFAULT NULL,
        rcm_text_nin           IN BOOLEAN := TRUE,
        dt_create_in           IN pat_rcm_det.dt_create%TYPE DEFAULT NULL,
        dt_create_nin          IN BOOLEAN := TRUE,
        where_in               VARCHAR2,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_patient_in         IN pat_rcm_det.id_patient%TYPE,
        id_institution_in     IN pat_rcm_det.id_institution%TYPE,
        id_rcm_in             IN pat_rcm_det.id_rcm%TYPE,
        id_rcm_det_in         IN pat_rcm_det.id_rcm_det%TYPE,
        id_rcm_orig_in        IN pat_rcm_det.id_rcm_orig%TYPE DEFAULT NULL,
        id_rcm_orig_value_in  IN pat_rcm_det.id_rcm_orig_value%TYPE DEFAULT NULL,
        create_user_in        IN pat_rcm_det.create_user%TYPE DEFAULT NULL,
        create_time_in        IN pat_rcm_det.create_time%TYPE DEFAULT NULL,
        create_institution_in IN pat_rcm_det.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN pat_rcm_det.update_user%TYPE DEFAULT NULL,
        update_time_in        IN pat_rcm_det.update_time%TYPE DEFAULT NULL,
        update_institution_in IN pat_rcm_det.update_institution%TYPE DEFAULT NULL,
        rcm_text_in           IN pat_rcm_det.rcm_text%TYPE DEFAULT NULL,
        dt_create_in          IN pat_rcm_det.dt_create%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_patient_in         IN pat_rcm_det.id_patient%TYPE,
        id_institution_in     IN pat_rcm_det.id_institution%TYPE,
        id_rcm_in             IN pat_rcm_det.id_rcm%TYPE,
        id_rcm_det_in         IN pat_rcm_det.id_rcm_det%TYPE,
        id_rcm_orig_in        IN pat_rcm_det.id_rcm_orig%TYPE DEFAULT NULL,
        id_rcm_orig_value_in  IN pat_rcm_det.id_rcm_orig_value%TYPE DEFAULT NULL,
        create_user_in        IN pat_rcm_det.create_user%TYPE DEFAULT NULL,
        create_time_in        IN pat_rcm_det.create_time%TYPE DEFAULT NULL,
        create_institution_in IN pat_rcm_det.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN pat_rcm_det.update_user%TYPE DEFAULT NULL,
        update_time_in        IN pat_rcm_det.update_time%TYPE DEFAULT NULL,
        update_institution_in IN pat_rcm_det.update_institution%TYPE DEFAULT NULL,
        rcm_text_in           IN pat_rcm_det.rcm_text%TYPE DEFAULT NULL,
        dt_create_in          IN pat_rcm_det.dt_create%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN pat_rcm_det%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN pat_rcm_det%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN pat_rcm_det_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN pat_rcm_det_tc,
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
        id_patient_in     IN pat_rcm_det.id_patient%TYPE,
        id_institution_in IN pat_rcm_det.id_institution%TYPE,
        id_rcm_in         IN pat_rcm_det.id_rcm%TYPE,
        id_rcm_det_in     IN pat_rcm_det.id_rcm_det%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_patient_in     IN pat_rcm_det.id_patient%TYPE,
        id_institution_in IN pat_rcm_det.id_institution%TYPE,
        id_rcm_in         IN pat_rcm_det.id_rcm%TYPE,
        id_rcm_det_in     IN pat_rcm_det.id_rcm_det%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows for primary key column ID_PATIENT
    PROCEDURE del_id_patient
    (
        id_patient_in   IN pat_rcm_det.id_patient%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_PATIENT
    PROCEDURE del_id_patient
    (
        id_patient_in   IN pat_rcm_det.id_patient%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for primary key column ID_INSTITUTION
    PROCEDURE del_id_institution
    (
        id_institution_in IN pat_rcm_det.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_INSTITUTION
    PROCEDURE del_id_institution
    (
        id_institution_in IN pat_rcm_det.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows for primary key column ID_RCM
    PROCEDURE del_id_rcm
    (
        id_rcm_in       IN pat_rcm_det.id_rcm%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_RCM
    PROCEDURE del_id_rcm
    (
        id_rcm_in       IN pat_rcm_det.id_rcm%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for primary key column ID_RCM_DET
    PROCEDURE del_id_rcm_det
    (
        id_rcm_det_in   IN pat_rcm_det.id_rcm_det%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_RCM_DET
    PROCEDURE del_id_rcm_det
    (
        id_rcm_det_in   IN pat_rcm_det.id_rcm_det%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this PRDT_INN_FK foreign key value
    PROCEDURE del_prdt_inn_fk
    (
        id_institution_in IN pat_rcm_det.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PRDT_INN_FK foreign key value
    PROCEDURE del_prdt_inn_fk
    (
        id_institution_in IN pat_rcm_det.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows for this PRDT_PAT_FK foreign key value
    PROCEDURE del_prdt_pat_fk
    (
        id_patient_in   IN pat_rcm_det.id_patient%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PRDT_PAT_FK foreign key value
    PROCEDURE del_prdt_pat_fk
    (
        id_patient_in   IN pat_rcm_det.id_patient%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this PRDT_RCM_FK foreign key value
    PROCEDURE del_prdt_rcm_fk
    (
        id_rcm_in       IN pat_rcm_det.id_rcm%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PRDT_RCM_FK foreign key value
    PROCEDURE del_prdt_rcm_fk
    (
        id_rcm_in       IN pat_rcm_det.id_rcm%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this PRDT_ROG_FK foreign key value
    PROCEDURE del_prdt_rog_fk
    (
        id_rcm_orig_in  IN pat_rcm_det.id_rcm_orig%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PRDT_ROG_FK foreign key value
    PROCEDURE del_prdt_rog_fk
    (
        id_rcm_orig_in  IN pat_rcm_det.id_rcm_orig%TYPE,
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
    PROCEDURE initrec(pat_rcm_det_inout IN OUT pat_rcm_det%ROWTYPE);

    FUNCTION initrec RETURN pat_rcm_det%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN pat_rcm_det_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN pat_rcm_det_tc;

END ts_pat_rcm_det;
/
