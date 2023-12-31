/*-- Last Change Revision: $Rev: 2029283 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:50:48 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE ts_pat_cli_attributes
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Novembro 21, 2008 18:24:12
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "PAT_CLI_ATTRIBUTES"
    TYPE pat_cli_attributes_tc IS TABLE OF pat_cli_attributes%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE pat_cli_attributes_ntt IS TABLE OF pat_cli_attributes%ROWTYPE;
    TYPE pat_cli_attributes_vat IS VARRAY(100) OF pat_cli_attributes%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF pat_cli_attributes%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF pat_cli_attributes%ROWTYPE;
    TYPE vat IS VARRAY(100) OF pat_cli_attributes%ROWTYPE;

    -- Column Collection based on column "ID_PAT_CLI_ATTRIBUTES"
    TYPE id_pat_cli_attributes_cc IS TABLE OF pat_cli_attributes.id_pat_cli_attributes%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_PATIENT"
    TYPE id_patient_cc IS TABLE OF pat_cli_attributes.id_patient%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_BREAST_FEED"
    TYPE flg_breast_feed_cc IS TABLE OF pat_cli_attributes.flg_breast_feed%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_PREGNANCY"
    TYPE flg_pregnancy_cc IS TABLE OF pat_cli_attributes.flg_pregnancy%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ADW_LAST_UPDATE"
    TYPE adw_last_update_cc IS TABLE OF pat_cli_attributes.adw_last_update%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_INSTITUTION"
    TYPE id_institution_cc IS TABLE OF pat_cli_attributes.id_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_RECM"
    TYPE id_recm_cc IS TABLE OF pat_cli_attributes.id_recm%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_VAL_RECM"
    TYPE dt_val_recm_cc IS TABLE OF pat_cli_attributes.dt_val_recm%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_EPISODE"
    TYPE id_episode_cc IS TABLE OF pat_cli_attributes.id_episode%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_pat_cli_attributes_in IN pat_cli_attributes.id_pat_cli_attributes%TYPE,
        id_patient_in            IN pat_cli_attributes.id_patient%TYPE DEFAULT NULL,
        flg_breast_feed_in       IN pat_cli_attributes.flg_breast_feed%TYPE DEFAULT NULL,
        flg_pregnancy_in         IN pat_cli_attributes.flg_pregnancy%TYPE DEFAULT NULL,
        adw_last_update_in       IN pat_cli_attributes.adw_last_update%TYPE DEFAULT SYSDATE,
        id_institution_in        IN pat_cli_attributes.id_institution%TYPE DEFAULT NULL,
        id_recm_in               IN pat_cli_attributes.id_recm%TYPE DEFAULT NULL,
        dt_val_recm_in           IN pat_cli_attributes.dt_val_recm%TYPE DEFAULT NULL,
        id_episode_in            IN pat_cli_attributes.id_episode%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_pat_cli_attributes_in IN pat_cli_attributes.id_pat_cli_attributes%TYPE,
        id_patient_in            IN pat_cli_attributes.id_patient%TYPE DEFAULT NULL,
        flg_breast_feed_in       IN pat_cli_attributes.flg_breast_feed%TYPE DEFAULT NULL,
        flg_pregnancy_in         IN pat_cli_attributes.flg_pregnancy%TYPE DEFAULT NULL,
        adw_last_update_in       IN pat_cli_attributes.adw_last_update%TYPE DEFAULT SYSDATE,
        id_institution_in        IN pat_cli_attributes.id_institution%TYPE DEFAULT NULL,
        id_recm_in               IN pat_cli_attributes.id_recm%TYPE DEFAULT NULL,
        dt_val_recm_in           IN pat_cli_attributes.dt_val_recm%TYPE DEFAULT NULL,
        id_episode_in            IN pat_cli_attributes.id_episode%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    -- Specify whether or not a primary key value should be generated.
    PROCEDURE ins
    (
        rec_in          IN pat_cli_attributes%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN pat_cli_attributes%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN pat_cli_attributes_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN pat_cli_attributes_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Return next primary key value using the named sequence.
    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN pat_cli_attributes.id_pat_cli_attributes%TYPE;

    -- Insert one row, generating hidden primary key using a sequence
    PROCEDURE ins
    (
        id_patient_in      IN pat_cli_attributes.id_patient%TYPE DEFAULT NULL,
        flg_breast_feed_in IN pat_cli_attributes.flg_breast_feed%TYPE DEFAULT NULL,
        flg_pregnancy_in   IN pat_cli_attributes.flg_pregnancy%TYPE DEFAULT NULL,
        adw_last_update_in IN pat_cli_attributes.adw_last_update%TYPE DEFAULT SYSDATE,
        id_institution_in  IN pat_cli_attributes.id_institution%TYPE DEFAULT NULL,
        id_recm_in         IN pat_cli_attributes.id_recm%TYPE DEFAULT NULL,
        dt_val_recm_in     IN pat_cli_attributes.dt_val_recm%TYPE DEFAULT NULL,
        id_episode_in      IN pat_cli_attributes.id_episode%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_patient_in      IN pat_cli_attributes.id_patient%TYPE DEFAULT NULL,
        flg_breast_feed_in IN pat_cli_attributes.flg_breast_feed%TYPE DEFAULT NULL,
        flg_pregnancy_in   IN pat_cli_attributes.flg_pregnancy%TYPE DEFAULT NULL,
        adw_last_update_in IN pat_cli_attributes.adw_last_update%TYPE DEFAULT SYSDATE,
        id_institution_in  IN pat_cli_attributes.id_institution%TYPE DEFAULT NULL,
        id_recm_in         IN pat_cli_attributes.id_recm%TYPE DEFAULT NULL,
        dt_val_recm_in     IN pat_cli_attributes.dt_val_recm%TYPE DEFAULT NULL,
        id_episode_in      IN pat_cli_attributes.id_episode%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row, returning primary key generated by sequence
    PROCEDURE ins
    (
        id_patient_in             IN pat_cli_attributes.id_patient%TYPE DEFAULT NULL,
        flg_breast_feed_in        IN pat_cli_attributes.flg_breast_feed%TYPE DEFAULT NULL,
        flg_pregnancy_in          IN pat_cli_attributes.flg_pregnancy%TYPE DEFAULT NULL,
        adw_last_update_in        IN pat_cli_attributes.adw_last_update%TYPE DEFAULT SYSDATE,
        id_institution_in         IN pat_cli_attributes.id_institution%TYPE DEFAULT NULL,
        id_recm_in                IN pat_cli_attributes.id_recm%TYPE DEFAULT NULL,
        dt_val_recm_in            IN pat_cli_attributes.dt_val_recm%TYPE DEFAULT NULL,
        id_episode_in             IN pat_cli_attributes.id_episode%TYPE DEFAULT NULL,
        id_pat_cli_attributes_out IN OUT pat_cli_attributes.id_pat_cli_attributes%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_patient_in             IN pat_cli_attributes.id_patient%TYPE DEFAULT NULL,
        flg_breast_feed_in        IN pat_cli_attributes.flg_breast_feed%TYPE DEFAULT NULL,
        flg_pregnancy_in          IN pat_cli_attributes.flg_pregnancy%TYPE DEFAULT NULL,
        adw_last_update_in        IN pat_cli_attributes.adw_last_update%TYPE DEFAULT SYSDATE,
        id_institution_in         IN pat_cli_attributes.id_institution%TYPE DEFAULT NULL,
        id_recm_in                IN pat_cli_attributes.id_recm%TYPE DEFAULT NULL,
        dt_val_recm_in            IN pat_cli_attributes.dt_val_recm%TYPE DEFAULT NULL,
        id_episode_in             IN pat_cli_attributes.id_episode%TYPE DEFAULT NULL,
        id_pat_cli_attributes_out IN OUT pat_cli_attributes.id_pat_cli_attributes%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row with function, return generated primary key
    FUNCTION ins
    (
        id_patient_in      IN pat_cli_attributes.id_patient%TYPE DEFAULT NULL,
        flg_breast_feed_in IN pat_cli_attributes.flg_breast_feed%TYPE DEFAULT NULL,
        flg_pregnancy_in   IN pat_cli_attributes.flg_pregnancy%TYPE DEFAULT NULL,
        adw_last_update_in IN pat_cli_attributes.adw_last_update%TYPE DEFAULT SYSDATE,
        id_institution_in  IN pat_cli_attributes.id_institution%TYPE DEFAULT NULL,
        id_recm_in         IN pat_cli_attributes.id_recm%TYPE DEFAULT NULL,
        dt_val_recm_in     IN pat_cli_attributes.dt_val_recm%TYPE DEFAULT NULL,
        id_episode_in      IN pat_cli_attributes.id_episode%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    ) RETURN pat_cli_attributes.id_pat_cli_attributes%TYPE;

    FUNCTION ins
    (
        id_patient_in      IN pat_cli_attributes.id_patient%TYPE DEFAULT NULL,
        flg_breast_feed_in IN pat_cli_attributes.flg_breast_feed%TYPE DEFAULT NULL,
        flg_pregnancy_in   IN pat_cli_attributes.flg_pregnancy%TYPE DEFAULT NULL,
        adw_last_update_in IN pat_cli_attributes.adw_last_update%TYPE DEFAULT SYSDATE,
        id_institution_in  IN pat_cli_attributes.id_institution%TYPE DEFAULT NULL,
        id_recm_in         IN pat_cli_attributes.id_recm%TYPE DEFAULT NULL,
        dt_val_recm_in     IN pat_cli_attributes.dt_val_recm%TYPE DEFAULT NULL,
        id_episode_in      IN pat_cli_attributes.id_episode%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    ) RETURN pat_cli_attributes.id_pat_cli_attributes%TYPE;

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        id_pat_cli_attributes_in IN pat_cli_attributes.id_pat_cli_attributes%TYPE,
        id_patient_in            IN pat_cli_attributes.id_patient%TYPE DEFAULT NULL,
        id_patient_nin           IN BOOLEAN := TRUE,
        flg_breast_feed_in       IN pat_cli_attributes.flg_breast_feed%TYPE DEFAULT NULL,
        flg_breast_feed_nin      IN BOOLEAN := TRUE,
        flg_pregnancy_in         IN pat_cli_attributes.flg_pregnancy%TYPE DEFAULT NULL,
        flg_pregnancy_nin        IN BOOLEAN := TRUE,
        adw_last_update_in       IN pat_cli_attributes.adw_last_update%TYPE DEFAULT NULL,
        adw_last_update_nin      IN BOOLEAN := TRUE,
        id_institution_in        IN pat_cli_attributes.id_institution%TYPE DEFAULT NULL,
        id_institution_nin       IN BOOLEAN := TRUE,
        id_recm_in               IN pat_cli_attributes.id_recm%TYPE DEFAULT NULL,
        id_recm_nin              IN BOOLEAN := TRUE,
        dt_val_recm_in           IN pat_cli_attributes.dt_val_recm%TYPE DEFAULT NULL,
        dt_val_recm_nin          IN BOOLEAN := TRUE,
        id_episode_in            IN pat_cli_attributes.id_episode%TYPE DEFAULT NULL,
        id_episode_nin           IN BOOLEAN := TRUE,
        handle_error_in          IN BOOLEAN := TRUE,
        rows_out                 IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_pat_cli_attributes_in IN pat_cli_attributes.id_pat_cli_attributes%TYPE,
        id_patient_in            IN pat_cli_attributes.id_patient%TYPE DEFAULT NULL,
        id_patient_nin           IN BOOLEAN := TRUE,
        flg_breast_feed_in       IN pat_cli_attributes.flg_breast_feed%TYPE DEFAULT NULL,
        flg_breast_feed_nin      IN BOOLEAN := TRUE,
        flg_pregnancy_in         IN pat_cli_attributes.flg_pregnancy%TYPE DEFAULT NULL,
        flg_pregnancy_nin        IN BOOLEAN := TRUE,
        adw_last_update_in       IN pat_cli_attributes.adw_last_update%TYPE DEFAULT NULL,
        adw_last_update_nin      IN BOOLEAN := TRUE,
        id_institution_in        IN pat_cli_attributes.id_institution%TYPE DEFAULT NULL,
        id_institution_nin       IN BOOLEAN := TRUE,
        id_recm_in               IN pat_cli_attributes.id_recm%TYPE DEFAULT NULL,
        id_recm_nin              IN BOOLEAN := TRUE,
        dt_val_recm_in           IN pat_cli_attributes.dt_val_recm%TYPE DEFAULT NULL,
        dt_val_recm_nin          IN BOOLEAN := TRUE,
        id_episode_in            IN pat_cli_attributes.id_episode%TYPE DEFAULT NULL,
        id_episode_nin           IN BOOLEAN := TRUE,
        handle_error_in          IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        id_patient_in       IN pat_cli_attributes.id_patient%TYPE DEFAULT NULL,
        id_patient_nin      IN BOOLEAN := TRUE,
        flg_breast_feed_in  IN pat_cli_attributes.flg_breast_feed%TYPE DEFAULT NULL,
        flg_breast_feed_nin IN BOOLEAN := TRUE,
        flg_pregnancy_in    IN pat_cli_attributes.flg_pregnancy%TYPE DEFAULT NULL,
        flg_pregnancy_nin   IN BOOLEAN := TRUE,
        adw_last_update_in  IN pat_cli_attributes.adw_last_update%TYPE DEFAULT NULL,
        adw_last_update_nin IN BOOLEAN := TRUE,
        id_institution_in   IN pat_cli_attributes.id_institution%TYPE DEFAULT NULL,
        id_institution_nin  IN BOOLEAN := TRUE,
        id_recm_in          IN pat_cli_attributes.id_recm%TYPE DEFAULT NULL,
        id_recm_nin         IN BOOLEAN := TRUE,
        dt_val_recm_in      IN pat_cli_attributes.dt_val_recm%TYPE DEFAULT NULL,
        dt_val_recm_nin     IN BOOLEAN := TRUE,
        id_episode_in       IN pat_cli_attributes.id_episode%TYPE DEFAULT NULL,
        id_episode_nin      IN BOOLEAN := TRUE,
        where_in            VARCHAR2 DEFAULT NULL,
        handle_error_in     IN BOOLEAN := TRUE,
        rows_out            IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_patient_in       IN pat_cli_attributes.id_patient%TYPE DEFAULT NULL,
        id_patient_nin      IN BOOLEAN := TRUE,
        flg_breast_feed_in  IN pat_cli_attributes.flg_breast_feed%TYPE DEFAULT NULL,
        flg_breast_feed_nin IN BOOLEAN := TRUE,
        flg_pregnancy_in    IN pat_cli_attributes.flg_pregnancy%TYPE DEFAULT NULL,
        flg_pregnancy_nin   IN BOOLEAN := TRUE,
        adw_last_update_in  IN pat_cli_attributes.adw_last_update%TYPE DEFAULT NULL,
        adw_last_update_nin IN BOOLEAN := TRUE,
        id_institution_in   IN pat_cli_attributes.id_institution%TYPE DEFAULT NULL,
        id_institution_nin  IN BOOLEAN := TRUE,
        id_recm_in          IN pat_cli_attributes.id_recm%TYPE DEFAULT NULL,
        id_recm_nin         IN BOOLEAN := TRUE,
        dt_val_recm_in      IN pat_cli_attributes.dt_val_recm%TYPE DEFAULT NULL,
        dt_val_recm_nin     IN BOOLEAN := TRUE,
        id_episode_in       IN pat_cli_attributes.id_episode%TYPE DEFAULT NULL,
        id_episode_nin      IN BOOLEAN := TRUE,
        where_in            VARCHAR2 DEFAULT NULL,
        handle_error_in     IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_pat_cli_attributes_in IN pat_cli_attributes.id_pat_cli_attributes%TYPE,
        id_patient_in            IN pat_cli_attributes.id_patient%TYPE DEFAULT NULL,
        flg_breast_feed_in       IN pat_cli_attributes.flg_breast_feed%TYPE DEFAULT NULL,
        flg_pregnancy_in         IN pat_cli_attributes.flg_pregnancy%TYPE DEFAULT NULL,
        adw_last_update_in       IN pat_cli_attributes.adw_last_update%TYPE DEFAULT NULL,
        id_institution_in        IN pat_cli_attributes.id_institution%TYPE DEFAULT NULL,
        id_recm_in               IN pat_cli_attributes.id_recm%TYPE DEFAULT NULL,
        dt_val_recm_in           IN pat_cli_attributes.dt_val_recm%TYPE DEFAULT NULL,
        id_episode_in            IN pat_cli_attributes.id_episode%TYPE DEFAULT NULL,
        handle_error_in          IN BOOLEAN := TRUE,
        rows_out                 OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_pat_cli_attributes_in IN pat_cli_attributes.id_pat_cli_attributes%TYPE,
        id_patient_in            IN pat_cli_attributes.id_patient%TYPE DEFAULT NULL,
        flg_breast_feed_in       IN pat_cli_attributes.flg_breast_feed%TYPE DEFAULT NULL,
        flg_pregnancy_in         IN pat_cli_attributes.flg_pregnancy%TYPE DEFAULT NULL,
        adw_last_update_in       IN pat_cli_attributes.adw_last_update%TYPE DEFAULT NULL,
        id_institution_in        IN pat_cli_attributes.id_institution%TYPE DEFAULT NULL,
        id_recm_in               IN pat_cli_attributes.id_recm%TYPE DEFAULT NULL,
        dt_val_recm_in           IN pat_cli_attributes.dt_val_recm%TYPE DEFAULT NULL,
        id_episode_in            IN pat_cli_attributes.id_episode%TYPE DEFAULT NULL,
        handle_error_in          IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN pat_cli_attributes%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN pat_cli_attributes%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN pat_cli_attributes_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN pat_cli_attributes_tc,
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
        id_pat_cli_attributes_in IN pat_cli_attributes.id_pat_cli_attributes%TYPE,
        handle_error_in          IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_pat_cli_attributes_in IN pat_cli_attributes.id_pat_cli_attributes%TYPE,
        handle_error_in          IN BOOLEAN := TRUE,
        rows_out                 OUT table_varchar
    );

    -- Delete all rows for primary key column ID_PAT_CLI_ATTRIBUTES
    PROCEDURE del_id_pat_cli_attributes
    (
        id_pat_cli_attributes_in IN pat_cli_attributes.id_pat_cli_attributes%TYPE,
        handle_error_in          IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_PAT_CLI_ATTRIBUTES
    PROCEDURE del_id_pat_cli_attributes
    (
        id_pat_cli_attributes_in IN pat_cli_attributes.id_pat_cli_attributes%TYPE,
        handle_error_in          IN BOOLEAN := TRUE,
        rows_out                 OUT table_varchar
    );

    -- Delete all rows for this PTCAT_EPIS_FK foreign key value
    PROCEDURE del_ptcat_epis_fk
    (
        id_episode_in   IN pat_cli_attributes.id_episode%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PTCAT_EPIS_FK foreign key value
    PROCEDURE del_ptcat_epis_fk
    (
        id_episode_in   IN pat_cli_attributes.id_episode%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this PTCAT_INST_FK foreign key value
    PROCEDURE del_ptcat_inst_fk
    (
        id_institution_in IN pat_cli_attributes.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PTCAT_INST_FK foreign key value
    PROCEDURE del_ptcat_inst_fk
    (
        id_institution_in IN pat_cli_attributes.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows for this PTCAT_PAT_FK foreign key value
    PROCEDURE del_ptcat_pat_fk
    (
        id_patient_in   IN pat_cli_attributes.id_patient%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PTCAT_PAT_FK foreign key value
    PROCEDURE del_ptcat_pat_fk
    (
        id_patient_in   IN pat_cli_attributes.id_patient%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this PTCAT_RECM_FK foreign key value
    PROCEDURE del_ptcat_recm_fk
    (
        id_recm_in      IN pat_cli_attributes.id_recm%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PTCAT_RECM_FK foreign key value
    PROCEDURE del_ptcat_recm_fk
    (
        id_recm_in      IN pat_cli_attributes.id_recm%TYPE,
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
    PROCEDURE initrec(pat_cli_attributes_inout IN OUT pat_cli_attributes%ROWTYPE);

    FUNCTION initrec RETURN pat_cli_attributes%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN pat_cli_attributes_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN pat_cli_attributes_tc;

END ts_pat_cli_attributes;
/
