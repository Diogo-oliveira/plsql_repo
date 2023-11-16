/*-- Last Change Revision: $Rev: 2029105 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:48 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE ts_death_cause
/*
| Generated by or retrieved - DO NOT MODIFY!
| Created On: 2017-07-13 12:38:31
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on death_cause
    TYPE death_cause_tc IS TABLE OF death_cause%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE death_cause_ntt IS TABLE OF death_cause%ROWTYPE;
    TYPE death_cause_vat IS VARRAY(100) OF death_cause%ROWTYPE;

    -- Column Collection based on column ID_EPIS_DIAGNOSIS
    TYPE id_epis_diagnosis_cc IS TABLE OF death_cause.id_epis_diagnosis%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_DEATH_CAUSE
    TYPE id_death_cause_cc IS TABLE OF death_cause.id_death_cause%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_DIAGNOSIS
    TYPE id_diagnosis_cc IS TABLE OF death_cause.id_diagnosis%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_DEATH_REGISTRY
    TYPE id_death_registry_cc IS TABLE OF death_cause.id_death_registry%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column DEATH_CAUSE_RANK
    TYPE death_cause_rank_cc IS TABLE OF death_cause.death_cause_rank%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_USER
    TYPE create_user_cc IS TABLE OF death_cause.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_TIME
    TYPE create_time_cc IS TABLE OF death_cause.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_INSTITUTION
    TYPE create_institution_cc IS TABLE OF death_cause.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_USER
    TYPE update_user_cc IS TABLE OF death_cause.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_TIME
    TYPE update_time_cc IS TABLE OF death_cause.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_INSTITUTION
    TYPE update_institution_cc IS TABLE OF death_cause.update_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_DIAG_INST_OWNER
    TYPE id_diag_inst_owner_cc IS TABLE OF death_cause.id_diag_inst_owner%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_ALERT_DIAGNOSIS
    TYPE id_alert_diagnosis_cc IS TABLE OF death_cause.id_alert_diagnosis%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_ADIAG_INST_OWNER
    TYPE id_adiag_inst_owner_cc IS TABLE OF death_cause.id_adiag_inst_owner%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present (with rows_out)
    PROCEDURE ins
    (
        id_epis_diagnosis_in   IN death_cause.id_epis_diagnosis%TYPE,
        id_death_cause_in      IN death_cause.id_death_cause%TYPE,
        id_diagnosis_in        IN death_cause.id_diagnosis%TYPE,
        id_death_registry_in   IN death_cause.id_death_registry%TYPE DEFAULT NULL,
        death_cause_rank_in    IN death_cause.death_cause_rank%TYPE DEFAULT NULL,
        create_user_in         IN death_cause.create_user%TYPE DEFAULT NULL,
        create_time_in         IN death_cause.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN death_cause.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN death_cause.update_user%TYPE DEFAULT NULL,
        update_time_in         IN death_cause.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN death_cause.update_institution%TYPE DEFAULT NULL,
        id_diag_inst_owner_in  IN death_cause.id_diag_inst_owner%TYPE DEFAULT 0,
        id_alert_diagnosis_in  IN death_cause.id_alert_diagnosis%TYPE DEFAULT NULL,
        id_adiag_inst_owner_in IN death_cause.id_adiag_inst_owner%TYPE DEFAULT 0,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               OUT table_varchar
    );

    -- Insert one row, providing primary key if present (without rows_out)
    PROCEDURE ins
    (
        id_epis_diagnosis_in   IN death_cause.id_epis_diagnosis%TYPE,
        id_death_cause_in      IN death_cause.id_death_cause%TYPE,
        id_diagnosis_in        IN death_cause.id_diagnosis%TYPE,
        id_death_registry_in   IN death_cause.id_death_registry%TYPE DEFAULT NULL,
        death_cause_rank_in    IN death_cause.death_cause_rank%TYPE DEFAULT NULL,
        create_user_in         IN death_cause.create_user%TYPE DEFAULT NULL,
        create_time_in         IN death_cause.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN death_cause.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN death_cause.update_user%TYPE DEFAULT NULL,
        update_time_in         IN death_cause.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN death_cause.update_institution%TYPE DEFAULT NULL,
        id_diag_inst_owner_in  IN death_cause.id_diag_inst_owner%TYPE DEFAULT 0,
        id_alert_diagnosis_in  IN death_cause.id_alert_diagnosis%TYPE DEFAULT NULL,
        id_adiag_inst_owner_in IN death_cause.id_adiag_inst_owner%TYPE DEFAULT 0,
        handle_error_in        IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record
    -- Specify whether or not a primary key value should be generated
    PROCEDURE ins
    (
        rec_in          IN death_cause%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert a row based on a record
    -- Specify whether or not a primary key value should be generated
    PROCEDURE ins
    (
        rec_in          IN death_cause%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers
    PROCEDURE ins
    (
        rows_in         IN death_cause_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers
    PROCEDURE ins
    (
        rows_in         IN death_cause_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.
    PROCEDURE upd
    (
        id_epis_diagnosis_in    IN death_cause.id_epis_diagnosis%TYPE,
        id_death_cause_in       IN death_cause.id_death_cause%TYPE,
        id_diagnosis_in         IN death_cause.id_diagnosis%TYPE,
        id_death_registry_in    IN death_cause.id_death_registry%TYPE DEFAULT NULL,
        id_death_registry_nin   IN BOOLEAN := TRUE,
        death_cause_rank_in     IN death_cause.death_cause_rank%TYPE DEFAULT NULL,
        death_cause_rank_nin    IN BOOLEAN := TRUE,
        create_user_in          IN death_cause.create_user%TYPE DEFAULT NULL,
        create_user_nin         IN BOOLEAN := TRUE,
        create_time_in          IN death_cause.create_time%TYPE DEFAULT NULL,
        create_time_nin         IN BOOLEAN := TRUE,
        create_institution_in   IN death_cause.create_institution%TYPE DEFAULT NULL,
        create_institution_nin  IN BOOLEAN := TRUE,
        update_user_in          IN death_cause.update_user%TYPE DEFAULT NULL,
        update_user_nin         IN BOOLEAN := TRUE,
        update_time_in          IN death_cause.update_time%TYPE DEFAULT NULL,
        update_time_nin         IN BOOLEAN := TRUE,
        update_institution_in   IN death_cause.update_institution%TYPE DEFAULT NULL,
        update_institution_nin  IN BOOLEAN := TRUE,
        id_diag_inst_owner_in   IN death_cause.id_diag_inst_owner%TYPE DEFAULT NULL,
        id_diag_inst_owner_nin  IN BOOLEAN := TRUE,
        id_alert_diagnosis_in   IN death_cause.id_alert_diagnosis%TYPE DEFAULT NULL,
        id_alert_diagnosis_nin  IN BOOLEAN := TRUE,
        id_adiag_inst_owner_in  IN death_cause.id_adiag_inst_owner%TYPE DEFAULT NULL,
        id_adiag_inst_owner_nin IN BOOLEAN := TRUE,
        handle_error_in         IN BOOLEAN := TRUE,
        rows_out                IN OUT table_varchar
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.
    PROCEDURE upd
    (
        id_epis_diagnosis_in    IN death_cause.id_epis_diagnosis%TYPE,
        id_death_cause_in       IN death_cause.id_death_cause%TYPE,
        id_diagnosis_in         IN death_cause.id_diagnosis%TYPE,
        id_death_registry_in    IN death_cause.id_death_registry%TYPE DEFAULT NULL,
        id_death_registry_nin   IN BOOLEAN := TRUE,
        death_cause_rank_in     IN death_cause.death_cause_rank%TYPE DEFAULT NULL,
        death_cause_rank_nin    IN BOOLEAN := TRUE,
        create_user_in          IN death_cause.create_user%TYPE DEFAULT NULL,
        create_user_nin         IN BOOLEAN := TRUE,
        create_time_in          IN death_cause.create_time%TYPE DEFAULT NULL,
        create_time_nin         IN BOOLEAN := TRUE,
        create_institution_in   IN death_cause.create_institution%TYPE DEFAULT NULL,
        create_institution_nin  IN BOOLEAN := TRUE,
        update_user_in          IN death_cause.update_user%TYPE DEFAULT NULL,
        update_user_nin         IN BOOLEAN := TRUE,
        update_time_in          IN death_cause.update_time%TYPE DEFAULT NULL,
        update_time_nin         IN BOOLEAN := TRUE,
        update_institution_in   IN death_cause.update_institution%TYPE DEFAULT NULL,
        update_institution_nin  IN BOOLEAN := TRUE,
        id_diag_inst_owner_in   IN death_cause.id_diag_inst_owner%TYPE DEFAULT NULL,
        id_diag_inst_owner_nin  IN BOOLEAN := TRUE,
        id_alert_diagnosis_in   IN death_cause.id_alert_diagnosis%TYPE DEFAULT NULL,
        id_alert_diagnosis_nin  IN BOOLEAN := TRUE,
        id_adiag_inst_owner_in  IN death_cause.id_adiag_inst_owner%TYPE DEFAULT NULL,
        id_adiag_inst_owner_nin IN BOOLEAN := TRUE,
        handle_error_in         IN BOOLEAN := TRUE
    );

    --Update any/all columns by dynamic WHERE
    -- If you pass NULL, then the current column value is set to itself
    PROCEDURE upd
    (
        id_death_registry_in    IN death_cause.id_death_registry%TYPE DEFAULT NULL,
        id_death_registry_nin   IN BOOLEAN := TRUE,
        death_cause_rank_in     IN death_cause.death_cause_rank%TYPE DEFAULT NULL,
        death_cause_rank_nin    IN BOOLEAN := TRUE,
        create_user_in          IN death_cause.create_user%TYPE DEFAULT NULL,
        create_user_nin         IN BOOLEAN := TRUE,
        create_time_in          IN death_cause.create_time%TYPE DEFAULT NULL,
        create_time_nin         IN BOOLEAN := TRUE,
        create_institution_in   IN death_cause.create_institution%TYPE DEFAULT NULL,
        create_institution_nin  IN BOOLEAN := TRUE,
        update_user_in          IN death_cause.update_user%TYPE DEFAULT NULL,
        update_user_nin         IN BOOLEAN := TRUE,
        update_time_in          IN death_cause.update_time%TYPE DEFAULT NULL,
        update_time_nin         IN BOOLEAN := TRUE,
        update_institution_in   IN death_cause.update_institution%TYPE DEFAULT NULL,
        update_institution_nin  IN BOOLEAN := TRUE,
        id_diag_inst_owner_in   IN death_cause.id_diag_inst_owner%TYPE DEFAULT NULL,
        id_diag_inst_owner_nin  IN BOOLEAN := TRUE,
        id_alert_diagnosis_in   IN death_cause.id_alert_diagnosis%TYPE DEFAULT NULL,
        id_alert_diagnosis_nin  IN BOOLEAN := TRUE,
        id_adiag_inst_owner_in  IN death_cause.id_adiag_inst_owner%TYPE DEFAULT NULL,
        id_adiag_inst_owner_nin IN BOOLEAN := TRUE,
        where_in                IN VARCHAR2,
        handle_error_in         IN BOOLEAN := TRUE,
        rows_out                IN OUT table_varchar
    );

    --Update any/all columns by dynamic WHERE
    -- If you pass NULL, then the current column value is set to itself
    PROCEDURE upd
    (
        id_death_registry_in    IN death_cause.id_death_registry%TYPE DEFAULT NULL,
        id_death_registry_nin   IN BOOLEAN := TRUE,
        death_cause_rank_in     IN death_cause.death_cause_rank%TYPE DEFAULT NULL,
        death_cause_rank_nin    IN BOOLEAN := TRUE,
        create_user_in          IN death_cause.create_user%TYPE DEFAULT NULL,
        create_user_nin         IN BOOLEAN := TRUE,
        create_time_in          IN death_cause.create_time%TYPE DEFAULT NULL,
        create_time_nin         IN BOOLEAN := TRUE,
        create_institution_in   IN death_cause.create_institution%TYPE DEFAULT NULL,
        create_institution_nin  IN BOOLEAN := TRUE,
        update_user_in          IN death_cause.update_user%TYPE DEFAULT NULL,
        update_user_nin         IN BOOLEAN := TRUE,
        update_time_in          IN death_cause.update_time%TYPE DEFAULT NULL,
        update_time_nin         IN BOOLEAN := TRUE,
        update_institution_in   IN death_cause.update_institution%TYPE DEFAULT NULL,
        update_institution_nin  IN BOOLEAN := TRUE,
        id_diag_inst_owner_in   IN death_cause.id_diag_inst_owner%TYPE DEFAULT NULL,
        id_diag_inst_owner_nin  IN BOOLEAN := TRUE,
        id_alert_diagnosis_in   IN death_cause.id_alert_diagnosis%TYPE DEFAULT NULL,
        id_alert_diagnosis_nin  IN BOOLEAN := TRUE,
        id_adiag_inst_owner_in  IN death_cause.id_adiag_inst_owner%TYPE DEFAULT NULL,
        id_adiag_inst_owner_nin IN BOOLEAN := TRUE,
        where_in                IN VARCHAR2,
        handle_error_in         IN BOOLEAN := TRUE
    );

    --Update/insert with columns (with rows_out)
    PROCEDURE upd_ins
    (
        id_epis_diagnosis_in   IN death_cause.id_epis_diagnosis%TYPE,
        id_death_cause_in      IN death_cause.id_death_cause%TYPE,
        id_diagnosis_in        IN death_cause.id_diagnosis%TYPE,
        id_death_registry_in   IN death_cause.id_death_registry%TYPE DEFAULT NULL,
        death_cause_rank_in    IN death_cause.death_cause_rank%TYPE DEFAULT NULL,
        create_user_in         IN death_cause.create_user%TYPE DEFAULT NULL,
        create_time_in         IN death_cause.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN death_cause.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN death_cause.update_user%TYPE DEFAULT NULL,
        update_time_in         IN death_cause.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN death_cause.update_institution%TYPE DEFAULT NULL,
        id_diag_inst_owner_in  IN death_cause.id_diag_inst_owner%TYPE DEFAULT NULL,
        id_alert_diagnosis_in  IN death_cause.id_alert_diagnosis%TYPE DEFAULT NULL,
        id_adiag_inst_owner_in IN death_cause.id_adiag_inst_owner%TYPE DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    --Update/insert with columns (without rows_out)
    PROCEDURE upd_ins
    (
        id_epis_diagnosis_in   IN death_cause.id_epis_diagnosis%TYPE,
        id_death_cause_in      IN death_cause.id_death_cause%TYPE,
        id_diagnosis_in        IN death_cause.id_diagnosis%TYPE,
        id_death_registry_in   IN death_cause.id_death_registry%TYPE DEFAULT NULL,
        death_cause_rank_in    IN death_cause.death_cause_rank%TYPE DEFAULT NULL,
        create_user_in         IN death_cause.create_user%TYPE DEFAULT NULL,
        create_time_in         IN death_cause.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN death_cause.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN death_cause.update_user%TYPE DEFAULT NULL,
        update_time_in         IN death_cause.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN death_cause.update_institution%TYPE DEFAULT NULL,
        id_diag_inst_owner_in  IN death_cause.id_diag_inst_owner%TYPE DEFAULT NULL,
        id_alert_diagnosis_in  IN death_cause.id_alert_diagnosis%TYPE DEFAULT NULL,
        id_adiag_inst_owner_in IN death_cause.id_adiag_inst_owner%TYPE DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE
    );

    --Update record (with rows_out)
    PROCEDURE upd
    (
        rec_in          IN death_cause%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    --Update record (without rows_out)
    PROCEDURE upd
    (
        rec_in          IN death_cause%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    --Update collection (with rows_out)
    PROCEDURE upd
    (
        col_in            IN death_cause_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    --Update collection (without rows_out)
    PROCEDURE upd
    (
        col_in            IN death_cause_tc,
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
        id_epis_diagnosis_in IN death_cause.id_epis_diagnosis%TYPE,
        id_death_cause_in    IN death_cause.id_death_cause%TYPE,
        id_diagnosis_in      IN death_cause.id_diagnosis%TYPE,
        handle_error_in      IN BOOLEAN := TRUE,
        rows_out             OUT table_varchar
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_epis_diagnosis_in IN death_cause.id_epis_diagnosis%TYPE,
        id_death_cause_in    IN death_cause.id_death_cause%TYPE,
        id_diagnosis_in      IN death_cause.id_diagnosis%TYPE,
        handle_error_in      IN BOOLEAN := TRUE
    );

    -- Delete for unique value of DTHC_DTHC_UK
    PROCEDURE del_dthc_dthc_uk
    (
        id_death_cause_in IN death_cause.id_death_cause%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete for unique value of DTHC_DTHR_DCR_UK
    PROCEDURE del_dthc_dthr_dcr_uk
    (
        id_death_registry_in IN death_cause.id_death_registry%TYPE,
        death_cause_rank_in  IN death_cause.death_cause_rank%TYPE,
        handle_error_in      IN BOOLEAN := TRUE,
        rows_out             OUT table_varchar
    );

    -- Delete for unique value of DTHC_DTHC_UK
    PROCEDURE del_dthc_dthc_uk
    (
        id_death_cause_in IN death_cause.id_death_cause%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete for unique value of DTHC_DTHR_DCR_UK
    PROCEDURE del_dthc_dthr_dcr_uk
    (
        id_death_registry_in IN death_cause.id_death_registry%TYPE,
        death_cause_rank_in  IN death_cause.death_cause_rank%TYPE,
        handle_error_in      IN BOOLEAN := TRUE
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

    -- Delete all rows for this DC_ADI_FK foreign key value
    PROCEDURE del_dc_adi_fk
    (
        id_alert_diagnosis_in  IN death_cause.id_alert_diagnosis%TYPE,
        id_adiag_inst_owner_in IN death_cause.id_adiag_inst_owner%TYPE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               OUT table_varchar
    );

    -- Delete all rows for this DC_DIAG_FK foreign key value
    PROCEDURE del_dc_diag_fk
    (
        id_diagnosis_in       IN death_cause.id_diagnosis%TYPE,
        id_diag_inst_owner_in IN death_cause.id_diag_inst_owner%TYPE,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
    );

    -- Delete all rows for this DTHC_DTHR_FK foreign key value
    PROCEDURE del_dthc_dthr_fk
    (
        id_death_registry_in IN death_cause.id_death_registry%TYPE,
        handle_error_in      IN BOOLEAN := TRUE,
        rows_out             OUT table_varchar
    );

    -- Delete all rows for this DTHC_ED_FK foreign key value
    PROCEDURE del_dthc_ed_fk
    (
        id_epis_diagnosis_in IN death_cause.id_epis_diagnosis%TYPE,
        handle_error_in      IN BOOLEAN := TRUE,
        rows_out             OUT table_varchar
    );

    -- Delete all rows for this DC_ADI_FK foreign key value
    PROCEDURE del_dc_adi_fk
    (
        id_alert_diagnosis_in  IN death_cause.id_alert_diagnosis%TYPE,
        id_adiag_inst_owner_in IN death_cause.id_adiag_inst_owner%TYPE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    -- Delete all rows for this DC_DIAG_FK foreign key value
    PROCEDURE del_dc_diag_fk
    (
        id_diagnosis_in       IN death_cause.id_diagnosis%TYPE,
        id_diag_inst_owner_in IN death_cause.id_diag_inst_owner%TYPE,
        handle_error_in       IN BOOLEAN := TRUE
    );

    -- Delete all rows for this DTHC_DTHR_FK foreign key value
    PROCEDURE del_dthc_dthr_fk
    (
        id_death_registry_in IN death_cause.id_death_registry%TYPE,
        handle_error_in      IN BOOLEAN := TRUE
    );

    -- Delete all rows for this DTHC_ED_FK foreign key value
    PROCEDURE del_dthc_ed_fk
    (
        id_epis_diagnosis_in IN death_cause.id_epis_diagnosis%TYPE,
        handle_error_in      IN BOOLEAN := TRUE
    );

    -- Initialize a record with default values for columns in the table (prc)
    PROCEDURE initrec(death_cause_inout IN OUT death_cause%ROWTYPE);

    -- Initialize a record with default values for columns in the table (fnc)
    FUNCTION initrec RETURN death_cause%ROWTYPE;

    -- Get data rowid
    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN death_cause_tc;

    -- Get data rowid pragma autonomous transaccion
    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN death_cause_tc;

END ts_death_cause;