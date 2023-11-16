/*-- Last Change Revision: $Rev: 2029106 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:48 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE ts_death_cause_hist
/*
| Generated by or retrieved - DO NOT MODIFY!
| Created On: 2017-07-13 15:28:18
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on death_cause_hist
    TYPE death_cause_hist_tc IS TABLE OF death_cause_hist%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE death_cause_hist_ntt IS TABLE OF death_cause_hist%ROWTYPE;
    TYPE death_cause_hist_vat IS VARRAY(100) OF death_cause_hist%ROWTYPE;

    -- Column Collection based on column ID_DEATH_REGISTRY_HIST
    TYPE id_death_registry_hist_cc IS TABLE OF death_cause_hist.id_death_registry_hist%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_EPIS_DIAGNOSIS
    TYPE id_epis_diagnosis_cc IS TABLE OF death_cause_hist.id_epis_diagnosis%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_DIAGNOSIS
    TYPE id_diagnosis_cc IS TABLE OF death_cause_hist.id_diagnosis%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_DEATH_CAUSE_HIST
    TYPE id_death_cause_hist_cc IS TABLE OF death_cause_hist.id_death_cause_hist%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_DEATH_CAUSE
    TYPE id_death_cause_cc IS TABLE OF death_cause_hist.id_death_cause%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_DEATH_REGISTRY
    TYPE id_death_registry_cc IS TABLE OF death_cause_hist.id_death_registry%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column DEATH_CAUSE_RANK
    TYPE death_cause_rank_cc IS TABLE OF death_cause_hist.death_cause_rank%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_USER
    TYPE create_user_cc IS TABLE OF death_cause_hist.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_TIME
    TYPE create_time_cc IS TABLE OF death_cause_hist.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_INSTITUTION
    TYPE create_institution_cc IS TABLE OF death_cause_hist.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_USER
    TYPE update_user_cc IS TABLE OF death_cause_hist.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_TIME
    TYPE update_time_cc IS TABLE OF death_cause_hist.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_INSTITUTION
    TYPE update_institution_cc IS TABLE OF death_cause_hist.update_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_DIAG_INST_OWNER
    TYPE id_diag_inst_owner_cc IS TABLE OF death_cause_hist.id_diag_inst_owner%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_ALERT_DIAGNOSIS
    TYPE id_alert_diagnosis_cc IS TABLE OF death_cause_hist.id_alert_diagnosis%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_ADIAG_INST_OWNER
    TYPE id_adiag_inst_owner_cc IS TABLE OF death_cause_hist.id_adiag_inst_owner%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present (with rows_out)
    PROCEDURE ins
    (
        id_death_registry_hist_in IN death_cause_hist.id_death_registry_hist%TYPE,
        id_epis_diagnosis_in      IN death_cause_hist.id_epis_diagnosis%TYPE,
        id_diagnosis_in           IN death_cause_hist.id_diagnosis%TYPE,
        id_death_cause_hist_in    IN death_cause_hist.id_death_cause_hist%TYPE DEFAULT NULL,
        id_death_cause_in         IN death_cause_hist.id_death_cause%TYPE DEFAULT NULL,
        id_death_registry_in      IN death_cause_hist.id_death_registry%TYPE DEFAULT NULL,
        death_cause_rank_in       IN death_cause_hist.death_cause_rank%TYPE DEFAULT NULL,
        create_user_in            IN death_cause_hist.create_user%TYPE DEFAULT NULL,
        create_time_in            IN death_cause_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in     IN death_cause_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in            IN death_cause_hist.update_user%TYPE DEFAULT NULL,
        update_time_in            IN death_cause_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in     IN death_cause_hist.update_institution%TYPE DEFAULT NULL,
        id_diag_inst_owner_in     IN death_cause_hist.id_diag_inst_owner%TYPE DEFAULT 0,
        id_alert_diagnosis_in     IN death_cause_hist.id_alert_diagnosis%TYPE DEFAULT NULL,
        id_adiag_inst_owner_in    IN death_cause_hist.id_adiag_inst_owner%TYPE DEFAULT 0,
        handle_error_in           IN BOOLEAN := TRUE,
        rows_out                  OUT table_varchar
    );

    -- Insert one row, providing primary key if present (without rows_out)
    PROCEDURE ins
    (
        id_death_registry_hist_in IN death_cause_hist.id_death_registry_hist%TYPE,
        id_epis_diagnosis_in      IN death_cause_hist.id_epis_diagnosis%TYPE,
        id_diagnosis_in           IN death_cause_hist.id_diagnosis%TYPE,
        id_death_cause_hist_in    IN death_cause_hist.id_death_cause_hist%TYPE DEFAULT NULL,
        id_death_cause_in         IN death_cause_hist.id_death_cause%TYPE DEFAULT NULL,
        id_death_registry_in      IN death_cause_hist.id_death_registry%TYPE DEFAULT NULL,
        death_cause_rank_in       IN death_cause_hist.death_cause_rank%TYPE DEFAULT NULL,
        create_user_in            IN death_cause_hist.create_user%TYPE DEFAULT NULL,
        create_time_in            IN death_cause_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in     IN death_cause_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in            IN death_cause_hist.update_user%TYPE DEFAULT NULL,
        update_time_in            IN death_cause_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in     IN death_cause_hist.update_institution%TYPE DEFAULT NULL,
        id_diag_inst_owner_in     IN death_cause_hist.id_diag_inst_owner%TYPE DEFAULT 0,
        id_alert_diagnosis_in     IN death_cause_hist.id_alert_diagnosis%TYPE DEFAULT NULL,
        id_adiag_inst_owner_in    IN death_cause_hist.id_adiag_inst_owner%TYPE DEFAULT 0,
        handle_error_in           IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record
    -- Specify whether or not a primary key value should be generated
    PROCEDURE ins
    (
        rec_in          IN death_cause_hist%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert a row based on a record
    -- Specify whether or not a primary key value should be generated
    PROCEDURE ins
    (
        rec_in          IN death_cause_hist%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers
    PROCEDURE ins
    (
        rows_in         IN death_cause_hist_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers
    PROCEDURE ins
    (
        rows_in         IN death_cause_hist_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.
    PROCEDURE upd
    (
        id_death_registry_hist_in IN death_cause_hist.id_death_registry_hist%TYPE,
        id_epis_diagnosis_in      IN death_cause_hist.id_epis_diagnosis%TYPE,
        id_diagnosis_in           IN death_cause_hist.id_diagnosis%TYPE,
        id_death_cause_hist_in    IN death_cause_hist.id_death_cause_hist%TYPE DEFAULT NULL,
        id_death_cause_hist_nin   IN BOOLEAN := TRUE,
        id_death_cause_in         IN death_cause_hist.id_death_cause%TYPE DEFAULT NULL,
        id_death_cause_nin        IN BOOLEAN := TRUE,
        id_death_registry_in      IN death_cause_hist.id_death_registry%TYPE DEFAULT NULL,
        id_death_registry_nin     IN BOOLEAN := TRUE,
        death_cause_rank_in       IN death_cause_hist.death_cause_rank%TYPE DEFAULT NULL,
        death_cause_rank_nin      IN BOOLEAN := TRUE,
        create_user_in            IN death_cause_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin           IN BOOLEAN := TRUE,
        create_time_in            IN death_cause_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin           IN BOOLEAN := TRUE,
        create_institution_in     IN death_cause_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin    IN BOOLEAN := TRUE,
        update_user_in            IN death_cause_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin           IN BOOLEAN := TRUE,
        update_time_in            IN death_cause_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin           IN BOOLEAN := TRUE,
        update_institution_in     IN death_cause_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin    IN BOOLEAN := TRUE,
        id_diag_inst_owner_in     IN death_cause_hist.id_diag_inst_owner%TYPE DEFAULT NULL,
        id_diag_inst_owner_nin    IN BOOLEAN := TRUE,
        id_alert_diagnosis_in     IN death_cause_hist.id_alert_diagnosis%TYPE DEFAULT NULL,
        id_alert_diagnosis_nin    IN BOOLEAN := TRUE,
        id_adiag_inst_owner_in    IN death_cause_hist.id_adiag_inst_owner%TYPE DEFAULT NULL,
        id_adiag_inst_owner_nin   IN BOOLEAN := TRUE,
        handle_error_in           IN BOOLEAN := TRUE,
        rows_out                  IN OUT table_varchar
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.
    PROCEDURE upd
    (
        id_death_registry_hist_in IN death_cause_hist.id_death_registry_hist%TYPE,
        id_epis_diagnosis_in      IN death_cause_hist.id_epis_diagnosis%TYPE,
        id_diagnosis_in           IN death_cause_hist.id_diagnosis%TYPE,
        id_death_cause_hist_in    IN death_cause_hist.id_death_cause_hist%TYPE DEFAULT NULL,
        id_death_cause_hist_nin   IN BOOLEAN := TRUE,
        id_death_cause_in         IN death_cause_hist.id_death_cause%TYPE DEFAULT NULL,
        id_death_cause_nin        IN BOOLEAN := TRUE,
        id_death_registry_in      IN death_cause_hist.id_death_registry%TYPE DEFAULT NULL,
        id_death_registry_nin     IN BOOLEAN := TRUE,
        death_cause_rank_in       IN death_cause_hist.death_cause_rank%TYPE DEFAULT NULL,
        death_cause_rank_nin      IN BOOLEAN := TRUE,
        create_user_in            IN death_cause_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin           IN BOOLEAN := TRUE,
        create_time_in            IN death_cause_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin           IN BOOLEAN := TRUE,
        create_institution_in     IN death_cause_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin    IN BOOLEAN := TRUE,
        update_user_in            IN death_cause_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin           IN BOOLEAN := TRUE,
        update_time_in            IN death_cause_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin           IN BOOLEAN := TRUE,
        update_institution_in     IN death_cause_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin    IN BOOLEAN := TRUE,
        id_diag_inst_owner_in     IN death_cause_hist.id_diag_inst_owner%TYPE DEFAULT NULL,
        id_diag_inst_owner_nin    IN BOOLEAN := TRUE,
        id_alert_diagnosis_in     IN death_cause_hist.id_alert_diagnosis%TYPE DEFAULT NULL,
        id_alert_diagnosis_nin    IN BOOLEAN := TRUE,
        id_adiag_inst_owner_in    IN death_cause_hist.id_adiag_inst_owner%TYPE DEFAULT NULL,
        id_adiag_inst_owner_nin   IN BOOLEAN := TRUE,
        handle_error_in           IN BOOLEAN := TRUE
    );

    --Update any/all columns by dynamic WHERE
    -- If you pass NULL, then the current column value is set to itself
    PROCEDURE upd
    (
        id_death_cause_hist_in  IN death_cause_hist.id_death_cause_hist%TYPE DEFAULT NULL,
        id_death_cause_hist_nin IN BOOLEAN := TRUE,
        id_death_cause_in       IN death_cause_hist.id_death_cause%TYPE DEFAULT NULL,
        id_death_cause_nin      IN BOOLEAN := TRUE,
        id_death_registry_in    IN death_cause_hist.id_death_registry%TYPE DEFAULT NULL,
        id_death_registry_nin   IN BOOLEAN := TRUE,
        death_cause_rank_in     IN death_cause_hist.death_cause_rank%TYPE DEFAULT NULL,
        death_cause_rank_nin    IN BOOLEAN := TRUE,
        create_user_in          IN death_cause_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin         IN BOOLEAN := TRUE,
        create_time_in          IN death_cause_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin         IN BOOLEAN := TRUE,
        create_institution_in   IN death_cause_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin  IN BOOLEAN := TRUE,
        update_user_in          IN death_cause_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin         IN BOOLEAN := TRUE,
        update_time_in          IN death_cause_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin         IN BOOLEAN := TRUE,
        update_institution_in   IN death_cause_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin  IN BOOLEAN := TRUE,
        id_diag_inst_owner_in   IN death_cause_hist.id_diag_inst_owner%TYPE DEFAULT NULL,
        id_diag_inst_owner_nin  IN BOOLEAN := TRUE,
        id_alert_diagnosis_in   IN death_cause_hist.id_alert_diagnosis%TYPE DEFAULT NULL,
        id_alert_diagnosis_nin  IN BOOLEAN := TRUE,
        id_adiag_inst_owner_in  IN death_cause_hist.id_adiag_inst_owner%TYPE DEFAULT NULL,
        id_adiag_inst_owner_nin IN BOOLEAN := TRUE,
        where_in                IN VARCHAR2,
        handle_error_in         IN BOOLEAN := TRUE,
        rows_out                IN OUT table_varchar
    );

    --Update any/all columns by dynamic WHERE
    -- If you pass NULL, then the current column value is set to itself
    PROCEDURE upd
    (
        id_death_cause_hist_in  IN death_cause_hist.id_death_cause_hist%TYPE DEFAULT NULL,
        id_death_cause_hist_nin IN BOOLEAN := TRUE,
        id_death_cause_in       IN death_cause_hist.id_death_cause%TYPE DEFAULT NULL,
        id_death_cause_nin      IN BOOLEAN := TRUE,
        id_death_registry_in    IN death_cause_hist.id_death_registry%TYPE DEFAULT NULL,
        id_death_registry_nin   IN BOOLEAN := TRUE,
        death_cause_rank_in     IN death_cause_hist.death_cause_rank%TYPE DEFAULT NULL,
        death_cause_rank_nin    IN BOOLEAN := TRUE,
        create_user_in          IN death_cause_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin         IN BOOLEAN := TRUE,
        create_time_in          IN death_cause_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin         IN BOOLEAN := TRUE,
        create_institution_in   IN death_cause_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin  IN BOOLEAN := TRUE,
        update_user_in          IN death_cause_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin         IN BOOLEAN := TRUE,
        update_time_in          IN death_cause_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin         IN BOOLEAN := TRUE,
        update_institution_in   IN death_cause_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin  IN BOOLEAN := TRUE,
        id_diag_inst_owner_in   IN death_cause_hist.id_diag_inst_owner%TYPE DEFAULT NULL,
        id_diag_inst_owner_nin  IN BOOLEAN := TRUE,
        id_alert_diagnosis_in   IN death_cause_hist.id_alert_diagnosis%TYPE DEFAULT NULL,
        id_alert_diagnosis_nin  IN BOOLEAN := TRUE,
        id_adiag_inst_owner_in  IN death_cause_hist.id_adiag_inst_owner%TYPE DEFAULT NULL,
        id_adiag_inst_owner_nin IN BOOLEAN := TRUE,
        where_in                IN VARCHAR2,
        handle_error_in         IN BOOLEAN := TRUE
    );

    --Update/insert with columns (with rows_out)
    PROCEDURE upd_ins
    (
        id_death_registry_hist_in IN death_cause_hist.id_death_registry_hist%TYPE,
        id_epis_diagnosis_in      IN death_cause_hist.id_epis_diagnosis%TYPE,
        id_diagnosis_in           IN death_cause_hist.id_diagnosis%TYPE,
        id_death_cause_hist_in    IN death_cause_hist.id_death_cause_hist%TYPE DEFAULT NULL,
        id_death_cause_in         IN death_cause_hist.id_death_cause%TYPE DEFAULT NULL,
        id_death_registry_in      IN death_cause_hist.id_death_registry%TYPE DEFAULT NULL,
        death_cause_rank_in       IN death_cause_hist.death_cause_rank%TYPE DEFAULT NULL,
        create_user_in            IN death_cause_hist.create_user%TYPE DEFAULT NULL,
        create_time_in            IN death_cause_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in     IN death_cause_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in            IN death_cause_hist.update_user%TYPE DEFAULT NULL,
        update_time_in            IN death_cause_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in     IN death_cause_hist.update_institution%TYPE DEFAULT NULL,
        id_diag_inst_owner_in     IN death_cause_hist.id_diag_inst_owner%TYPE DEFAULT NULL,
        id_alert_diagnosis_in     IN death_cause_hist.id_alert_diagnosis%TYPE DEFAULT NULL,
        id_adiag_inst_owner_in    IN death_cause_hist.id_adiag_inst_owner%TYPE DEFAULT NULL,
        handle_error_in           IN BOOLEAN := TRUE,
        rows_out                  IN OUT table_varchar
    );

    --Update/insert with columns (without rows_out)
    PROCEDURE upd_ins
    (
        id_death_registry_hist_in IN death_cause_hist.id_death_registry_hist%TYPE,
        id_epis_diagnosis_in      IN death_cause_hist.id_epis_diagnosis%TYPE,
        id_diagnosis_in           IN death_cause_hist.id_diagnosis%TYPE,
        id_death_cause_hist_in    IN death_cause_hist.id_death_cause_hist%TYPE DEFAULT NULL,
        id_death_cause_in         IN death_cause_hist.id_death_cause%TYPE DEFAULT NULL,
        id_death_registry_in      IN death_cause_hist.id_death_registry%TYPE DEFAULT NULL,
        death_cause_rank_in       IN death_cause_hist.death_cause_rank%TYPE DEFAULT NULL,
        create_user_in            IN death_cause_hist.create_user%TYPE DEFAULT NULL,
        create_time_in            IN death_cause_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in     IN death_cause_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in            IN death_cause_hist.update_user%TYPE DEFAULT NULL,
        update_time_in            IN death_cause_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in     IN death_cause_hist.update_institution%TYPE DEFAULT NULL,
        id_diag_inst_owner_in     IN death_cause_hist.id_diag_inst_owner%TYPE DEFAULT NULL,
        id_alert_diagnosis_in     IN death_cause_hist.id_alert_diagnosis%TYPE DEFAULT NULL,
        id_adiag_inst_owner_in    IN death_cause_hist.id_adiag_inst_owner%TYPE DEFAULT NULL,
        handle_error_in           IN BOOLEAN := TRUE
    );

    --Update record (with rows_out)
    PROCEDURE upd
    (
        rec_in          IN death_cause_hist%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    --Update record (without rows_out)
    PROCEDURE upd
    (
        rec_in          IN death_cause_hist%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    --Update collection (with rows_out)
    PROCEDURE upd
    (
        col_in            IN death_cause_hist_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    --Update collection (without rows_out)
    PROCEDURE upd
    (
        col_in            IN death_cause_hist_tc,
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
        id_death_registry_hist_in IN death_cause_hist.id_death_registry_hist%TYPE,
        id_epis_diagnosis_in      IN death_cause_hist.id_epis_diagnosis%TYPE,
        id_diagnosis_in           IN death_cause_hist.id_diagnosis%TYPE,
        handle_error_in           IN BOOLEAN := TRUE,
        rows_out                  OUT table_varchar
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_death_registry_hist_in IN death_cause_hist.id_death_registry_hist%TYPE,
        id_epis_diagnosis_in      IN death_cause_hist.id_epis_diagnosis%TYPE,
        id_diagnosis_in           IN death_cause_hist.id_diagnosis%TYPE,
        handle_error_in           IN BOOLEAN := TRUE
    );

    -- Delete for unique value of DTCH_DTCH_UK
    PROCEDURE del_dtch_dtch_uk
    (
        id_death_cause_hist_in IN death_cause_hist.id_death_cause_hist%TYPE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               OUT table_varchar
    );

    -- Delete for unique value of DTCH_DTCH_UK
    PROCEDURE del_dtch_dtch_uk
    (
        id_death_cause_hist_in IN death_cause_hist.id_death_cause_hist%TYPE,
        handle_error_in        IN BOOLEAN := TRUE
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

    -- Delete all rows for this DTCH_DTRH_FK foreign key value
    PROCEDURE del_dtch_dtrh_fk
    (
        id_death_registry_hist_in IN death_cause_hist.id_death_registry_hist%TYPE,
        handle_error_in           IN BOOLEAN := TRUE,
        rows_out                  OUT table_varchar
    );

    -- Delete all rows for this DTCH_DTRH_FK foreign key value
    PROCEDURE del_dtch_dtrh_fk
    (
        id_death_registry_hist_in IN death_cause_hist.id_death_registry_hist%TYPE,
        handle_error_in           IN BOOLEAN := TRUE
    );

    -- Initialize a record with default values for columns in the table (prc)
    PROCEDURE initrec(death_cause_hist_inout IN OUT death_cause_hist%ROWTYPE);

    -- Initialize a record with default values for columns in the table (fnc)
    FUNCTION initrec RETURN death_cause_hist%ROWTYPE;

    -- Get data rowid
    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN death_cause_hist_tc;

    -- Get data rowid pragma autonomous transaccion
    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN death_cause_hist_tc;

END ts_death_cause_hist;