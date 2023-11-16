/*-- Last Change Revision: $Rev: 1769415 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2017-01-31 11:59:34 +0000 (ter, 31 jan 2017) $*/

CREATE OR REPLACE PACKAGE ts_death_registry_det_hist
/*
| Generated by or retrieved - DO NOT MODIFY!
| Created On: 2017-01-31 11:28:57
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on death_registry_det_hist
    TYPE death_registry_det_hist_tc IS TABLE OF death_registry_det_hist%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE death_registry_det_hist_ntt IS TABLE OF death_registry_det_hist%ROWTYPE;
    TYPE death_registry_det_hist_vat IS VARRAY(100) OF death_registry_det_hist%ROWTYPE;

    -- Column Collection based on column ID_DEATH_REGISTRY_DET_HIST
    TYPE id_death_registry_det_hist_cc IS TABLE OF death_registry_det_hist.id_death_registry_det_hist%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_DEATH_REGISTRY_HIST
    TYPE id_death_registry_hist_cc IS TABLE OF death_registry_det_hist.id_death_registry_hist%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column DT_DEATH_REGISTRY_HIST
    TYPE dt_death_registry_hist_cc IS TABLE OF death_registry_det_hist.dt_death_registry_hist%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_DEATH_REGISTRY
    TYPE id_death_registry_cc IS TABLE OF death_registry_det_hist.id_death_registry%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_DS_COMPONENT
    TYPE id_ds_component_cc IS TABLE OF death_registry_det_hist.id_ds_component%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column VALUE_N
    TYPE value_n_cc IS TABLE OF death_registry_det_hist.value_n%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column VALUE_TZ
    TYPE value_tz_cc IS TABLE OF death_registry_det_hist.value_tz%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column VALUE_VC2
    TYPE value_vc2_cc IS TABLE OF death_registry_det_hist.value_vc2%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UNIT_MEASURE_VALUE
    TYPE unit_measure_value_cc IS TABLE OF death_registry_det_hist.unit_measure_value%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_USER
    TYPE create_user_cc IS TABLE OF death_registry_det_hist.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_TIME
    TYPE create_time_cc IS TABLE OF death_registry_det_hist.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_INSTITUTION
    TYPE create_institution_cc IS TABLE OF death_registry_det_hist.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_USER
    TYPE update_user_cc IS TABLE OF death_registry_det_hist.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_TIME
    TYPE update_time_cc IS TABLE OF death_registry_det_hist.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_INSTITUTION
    TYPE update_institution_cc IS TABLE OF death_registry_det_hist.update_institution%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present (with rows_out)
    PROCEDURE ins
    (
        id_death_registry_det_hist_in IN death_registry_det_hist.id_death_registry_det_hist%TYPE,
        id_death_registry_hist_in     IN death_registry_det_hist.id_death_registry_hist%TYPE DEFAULT NULL,
        dt_death_registry_hist_in     IN death_registry_det_hist.dt_death_registry_hist%TYPE DEFAULT current_timestamp,
        id_death_registry_in          IN death_registry_det_hist.id_death_registry%TYPE DEFAULT NULL,
        id_ds_component_in            IN death_registry_det_hist.id_ds_component%TYPE DEFAULT NULL,
        value_n_in                    IN death_registry_det_hist.value_n%TYPE DEFAULT NULL,
        value_tz_in                   IN death_registry_det_hist.value_tz%TYPE DEFAULT NULL,
        value_vc2_in                  IN death_registry_det_hist.value_vc2%TYPE DEFAULT NULL,
        unit_measure_value_in         IN death_registry_det_hist.unit_measure_value%TYPE DEFAULT NULL,
        create_user_in                IN death_registry_det_hist.create_user%TYPE DEFAULT NULL,
        create_time_in                IN death_registry_det_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in         IN death_registry_det_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in                IN death_registry_det_hist.update_user%TYPE DEFAULT NULL,
        update_time_in                IN death_registry_det_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in         IN death_registry_det_hist.update_institution%TYPE DEFAULT NULL,
        handle_error_in               IN BOOLEAN := TRUE,
        rows_out                      OUT table_varchar
    );

    -- Insert one row, providing primary key if present (without rows_out)
    PROCEDURE ins
    (
        id_death_registry_det_hist_in IN death_registry_det_hist.id_death_registry_det_hist%TYPE,
        id_death_registry_hist_in     IN death_registry_det_hist.id_death_registry_hist%TYPE DEFAULT NULL,
        dt_death_registry_hist_in     IN death_registry_det_hist.dt_death_registry_hist%TYPE DEFAULT current_timestamp,
        id_death_registry_in          IN death_registry_det_hist.id_death_registry%TYPE DEFAULT NULL,
        id_ds_component_in            IN death_registry_det_hist.id_ds_component%TYPE DEFAULT NULL,
        value_n_in                    IN death_registry_det_hist.value_n%TYPE DEFAULT NULL,
        value_tz_in                   IN death_registry_det_hist.value_tz%TYPE DEFAULT NULL,
        value_vc2_in                  IN death_registry_det_hist.value_vc2%TYPE DEFAULT NULL,
        unit_measure_value_in         IN death_registry_det_hist.unit_measure_value%TYPE DEFAULT NULL,
        create_user_in                IN death_registry_det_hist.create_user%TYPE DEFAULT NULL,
        create_time_in                IN death_registry_det_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in         IN death_registry_det_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in                IN death_registry_det_hist.update_user%TYPE DEFAULT NULL,
        update_time_in                IN death_registry_det_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in         IN death_registry_det_hist.update_institution%TYPE DEFAULT NULL,
        handle_error_in               IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record
    -- Specify whether or not a primary key value should be generated
    PROCEDURE ins
    (
        rec_in          IN death_registry_det_hist%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert a row based on a record
    -- Specify whether or not a primary key value should be generated
    PROCEDURE ins
    (
        rec_in          IN death_registry_det_hist%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers
    PROCEDURE ins
    (
        rows_in         IN death_registry_det_hist_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers
    PROCEDURE ins
    (
        rows_in         IN death_registry_det_hist_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Return next primary key value using the named sequence
    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN death_registry_det_hist.id_death_registry_det_hist%TYPE;

    -- Insert one row, generating hidden primary key using a sequence
    PROCEDURE ins
    (
        id_death_registry_hist_in IN death_registry_det_hist.id_death_registry_hist%TYPE DEFAULT NULL,
        dt_death_registry_hist_in IN death_registry_det_hist.dt_death_registry_hist%TYPE DEFAULT current_timestamp,
        id_death_registry_in      IN death_registry_det_hist.id_death_registry%TYPE DEFAULT NULL,
        id_ds_component_in        IN death_registry_det_hist.id_ds_component%TYPE DEFAULT NULL,
        value_n_in                IN death_registry_det_hist.value_n%TYPE DEFAULT NULL,
        value_tz_in               IN death_registry_det_hist.value_tz%TYPE DEFAULT NULL,
        value_vc2_in              IN death_registry_det_hist.value_vc2%TYPE DEFAULT NULL,
        unit_measure_value_in     IN death_registry_det_hist.unit_measure_value%TYPE DEFAULT NULL,
        create_user_in            IN death_registry_det_hist.create_user%TYPE DEFAULT NULL,
        create_time_in            IN death_registry_det_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in     IN death_registry_det_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in            IN death_registry_det_hist.update_user%TYPE DEFAULT NULL,
        update_time_in            IN death_registry_det_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in     IN death_registry_det_hist.update_institution%TYPE DEFAULT NULL,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert one row, generating hidden primary key using a sequence
    PROCEDURE ins
    (
        id_death_registry_hist_in IN death_registry_det_hist.id_death_registry_hist%TYPE DEFAULT NULL,
        dt_death_registry_hist_in IN death_registry_det_hist.dt_death_registry_hist%TYPE DEFAULT current_timestamp,
        id_death_registry_in      IN death_registry_det_hist.id_death_registry%TYPE DEFAULT NULL,
        id_ds_component_in        IN death_registry_det_hist.id_ds_component%TYPE DEFAULT NULL,
        value_n_in                IN death_registry_det_hist.value_n%TYPE DEFAULT NULL,
        value_tz_in               IN death_registry_det_hist.value_tz%TYPE DEFAULT NULL,
        value_vc2_in              IN death_registry_det_hist.value_vc2%TYPE DEFAULT NULL,
        unit_measure_value_in     IN death_registry_det_hist.unit_measure_value%TYPE DEFAULT NULL,
        create_user_in            IN death_registry_det_hist.create_user%TYPE DEFAULT NULL,
        create_time_in            IN death_registry_det_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in     IN death_registry_det_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in            IN death_registry_det_hist.update_user%TYPE DEFAULT NULL,
        update_time_in            IN death_registry_det_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in     IN death_registry_det_hist.update_institution%TYPE DEFAULT NULL,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row, returning primary key generated by sequence
    PROCEDURE ins
    (
        id_death_registry_hist_in      IN death_registry_det_hist.id_death_registry_hist%TYPE DEFAULT NULL,
        dt_death_registry_hist_in      IN death_registry_det_hist.dt_death_registry_hist%TYPE DEFAULT current_timestamp,
        id_death_registry_in           IN death_registry_det_hist.id_death_registry%TYPE DEFAULT NULL,
        id_ds_component_in             IN death_registry_det_hist.id_ds_component%TYPE DEFAULT NULL,
        value_n_in                     IN death_registry_det_hist.value_n%TYPE DEFAULT NULL,
        value_tz_in                    IN death_registry_det_hist.value_tz%TYPE DEFAULT NULL,
        value_vc2_in                   IN death_registry_det_hist.value_vc2%TYPE DEFAULT NULL,
        unit_measure_value_in          IN death_registry_det_hist.unit_measure_value%TYPE DEFAULT NULL,
        create_user_in                 IN death_registry_det_hist.create_user%TYPE DEFAULT NULL,
        create_time_in                 IN death_registry_det_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in          IN death_registry_det_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in                 IN death_registry_det_hist.update_user%TYPE DEFAULT NULL,
        update_time_in                 IN death_registry_det_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in          IN death_registry_det_hist.update_institution%TYPE DEFAULT NULL,
        id_death_registry_det_hist_out IN OUT death_registry_det_hist.id_death_registry_det_hist%TYPE,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert one row, returning primary key generated by sequence
    PROCEDURE ins
    (
        id_death_registry_hist_in      IN death_registry_det_hist.id_death_registry_hist%TYPE DEFAULT NULL,
        dt_death_registry_hist_in      IN death_registry_det_hist.dt_death_registry_hist%TYPE DEFAULT current_timestamp,
        id_death_registry_in           IN death_registry_det_hist.id_death_registry%TYPE DEFAULT NULL,
        id_ds_component_in             IN death_registry_det_hist.id_ds_component%TYPE DEFAULT NULL,
        value_n_in                     IN death_registry_det_hist.value_n%TYPE DEFAULT NULL,
        value_tz_in                    IN death_registry_det_hist.value_tz%TYPE DEFAULT NULL,
        value_vc2_in                   IN death_registry_det_hist.value_vc2%TYPE DEFAULT NULL,
        unit_measure_value_in          IN death_registry_det_hist.unit_measure_value%TYPE DEFAULT NULL,
        create_user_in                 IN death_registry_det_hist.create_user%TYPE DEFAULT NULL,
        create_time_in                 IN death_registry_det_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in          IN death_registry_det_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in                 IN death_registry_det_hist.update_user%TYPE DEFAULT NULL,
        update_time_in                 IN death_registry_det_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in          IN death_registry_det_hist.update_institution%TYPE DEFAULT NULL,
        id_death_registry_det_hist_out IN OUT death_registry_det_hist.id_death_registry_det_hist%TYPE,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row with function, return generated primary key
    FUNCTION ins
    (
        id_death_registry_hist_in IN death_registry_det_hist.id_death_registry_hist%TYPE DEFAULT NULL,
        dt_death_registry_hist_in IN death_registry_det_hist.dt_death_registry_hist%TYPE DEFAULT current_timestamp,
        id_death_registry_in      IN death_registry_det_hist.id_death_registry%TYPE DEFAULT NULL,
        id_ds_component_in        IN death_registry_det_hist.id_ds_component%TYPE DEFAULT NULL,
        value_n_in                IN death_registry_det_hist.value_n%TYPE DEFAULT NULL,
        value_tz_in               IN death_registry_det_hist.value_tz%TYPE DEFAULT NULL,
        value_vc2_in              IN death_registry_det_hist.value_vc2%TYPE DEFAULT NULL,
        unit_measure_value_in     IN death_registry_det_hist.unit_measure_value%TYPE DEFAULT NULL,
        create_user_in            IN death_registry_det_hist.create_user%TYPE DEFAULT NULL,
        create_time_in            IN death_registry_det_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in     IN death_registry_det_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in            IN death_registry_det_hist.update_user%TYPE DEFAULT NULL,
        update_time_in            IN death_registry_det_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in     IN death_registry_det_hist.update_institution%TYPE DEFAULT NULL,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    ) RETURN death_registry_det_hist.id_death_registry_det_hist%TYPE;

    -- Insert one row with function, return generated primary key
    FUNCTION ins
    (
        id_death_registry_hist_in IN death_registry_det_hist.id_death_registry_hist%TYPE DEFAULT NULL,
        dt_death_registry_hist_in IN death_registry_det_hist.dt_death_registry_hist%TYPE DEFAULT current_timestamp,
        id_death_registry_in      IN death_registry_det_hist.id_death_registry%TYPE DEFAULT NULL,
        id_ds_component_in        IN death_registry_det_hist.id_ds_component%TYPE DEFAULT NULL,
        value_n_in                IN death_registry_det_hist.value_n%TYPE DEFAULT NULL,
        value_tz_in               IN death_registry_det_hist.value_tz%TYPE DEFAULT NULL,
        value_vc2_in              IN death_registry_det_hist.value_vc2%TYPE DEFAULT NULL,
        unit_measure_value_in     IN death_registry_det_hist.unit_measure_value%TYPE DEFAULT NULL,
        create_user_in            IN death_registry_det_hist.create_user%TYPE DEFAULT NULL,
        create_time_in            IN death_registry_det_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in     IN death_registry_det_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in            IN death_registry_det_hist.update_user%TYPE DEFAULT NULL,
        update_time_in            IN death_registry_det_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in     IN death_registry_det_hist.update_institution%TYPE DEFAULT NULL,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE
    ) RETURN death_registry_det_hist.id_death_registry_det_hist%TYPE;

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.
    PROCEDURE upd
    (
        id_death_registry_det_hist_in IN death_registry_det_hist.id_death_registry_det_hist%TYPE,
        id_death_registry_hist_in     IN death_registry_det_hist.id_death_registry_hist%TYPE DEFAULT NULL,
        id_death_registry_hist_nin    IN BOOLEAN := TRUE,
        dt_death_registry_hist_in     IN death_registry_det_hist.dt_death_registry_hist%TYPE DEFAULT NULL,
        dt_death_registry_hist_nin    IN BOOLEAN := TRUE,
        id_death_registry_in          IN death_registry_det_hist.id_death_registry%TYPE DEFAULT NULL,
        id_death_registry_nin         IN BOOLEAN := TRUE,
        id_ds_component_in            IN death_registry_det_hist.id_ds_component%TYPE DEFAULT NULL,
        id_ds_component_nin           IN BOOLEAN := TRUE,
        value_n_in                    IN death_registry_det_hist.value_n%TYPE DEFAULT NULL,
        value_n_nin                   IN BOOLEAN := TRUE,
        value_tz_in                   IN death_registry_det_hist.value_tz%TYPE DEFAULT NULL,
        value_tz_nin                  IN BOOLEAN := TRUE,
        value_vc2_in                  IN death_registry_det_hist.value_vc2%TYPE DEFAULT NULL,
        value_vc2_nin                 IN BOOLEAN := TRUE,
        unit_measure_value_in         IN death_registry_det_hist.unit_measure_value%TYPE DEFAULT NULL,
        unit_measure_value_nin        IN BOOLEAN := TRUE,
        create_user_in                IN death_registry_det_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin               IN BOOLEAN := TRUE,
        create_time_in                IN death_registry_det_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin               IN BOOLEAN := TRUE,
        create_institution_in         IN death_registry_det_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin        IN BOOLEAN := TRUE,
        update_user_in                IN death_registry_det_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin               IN BOOLEAN := TRUE,
        update_time_in                IN death_registry_det_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin               IN BOOLEAN := TRUE,
        update_institution_in         IN death_registry_det_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin        IN BOOLEAN := TRUE,
        handle_error_in               IN BOOLEAN := TRUE,
        rows_out                      IN OUT table_varchar
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.
    PROCEDURE upd
    (
        id_death_registry_det_hist_in IN death_registry_det_hist.id_death_registry_det_hist%TYPE,
        id_death_registry_hist_in     IN death_registry_det_hist.id_death_registry_hist%TYPE DEFAULT NULL,
        id_death_registry_hist_nin    IN BOOLEAN := TRUE,
        dt_death_registry_hist_in     IN death_registry_det_hist.dt_death_registry_hist%TYPE DEFAULT NULL,
        dt_death_registry_hist_nin    IN BOOLEAN := TRUE,
        id_death_registry_in          IN death_registry_det_hist.id_death_registry%TYPE DEFAULT NULL,
        id_death_registry_nin         IN BOOLEAN := TRUE,
        id_ds_component_in            IN death_registry_det_hist.id_ds_component%TYPE DEFAULT NULL,
        id_ds_component_nin           IN BOOLEAN := TRUE,
        value_n_in                    IN death_registry_det_hist.value_n%TYPE DEFAULT NULL,
        value_n_nin                   IN BOOLEAN := TRUE,
        value_tz_in                   IN death_registry_det_hist.value_tz%TYPE DEFAULT NULL,
        value_tz_nin                  IN BOOLEAN := TRUE,
        value_vc2_in                  IN death_registry_det_hist.value_vc2%TYPE DEFAULT NULL,
        value_vc2_nin                 IN BOOLEAN := TRUE,
        unit_measure_value_in         IN death_registry_det_hist.unit_measure_value%TYPE DEFAULT NULL,
        unit_measure_value_nin        IN BOOLEAN := TRUE,
        create_user_in                IN death_registry_det_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin               IN BOOLEAN := TRUE,
        create_time_in                IN death_registry_det_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin               IN BOOLEAN := TRUE,
        create_institution_in         IN death_registry_det_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin        IN BOOLEAN := TRUE,
        update_user_in                IN death_registry_det_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin               IN BOOLEAN := TRUE,
        update_time_in                IN death_registry_det_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin               IN BOOLEAN := TRUE,
        update_institution_in         IN death_registry_det_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin        IN BOOLEAN := TRUE,
        handle_error_in               IN BOOLEAN := TRUE
    );

    --Update any/all columns by dynamic WHERE
    -- If you pass NULL, then the current column value is set to itself
    PROCEDURE upd
    (
        id_death_registry_hist_in  IN death_registry_det_hist.id_death_registry_hist%TYPE DEFAULT NULL,
        id_death_registry_hist_nin IN BOOLEAN := TRUE,
        dt_death_registry_hist_in  IN death_registry_det_hist.dt_death_registry_hist%TYPE DEFAULT NULL,
        dt_death_registry_hist_nin IN BOOLEAN := TRUE,
        id_death_registry_in       IN death_registry_det_hist.id_death_registry%TYPE DEFAULT NULL,
        id_death_registry_nin      IN BOOLEAN := TRUE,
        id_ds_component_in         IN death_registry_det_hist.id_ds_component%TYPE DEFAULT NULL,
        id_ds_component_nin        IN BOOLEAN := TRUE,
        value_n_in                 IN death_registry_det_hist.value_n%TYPE DEFAULT NULL,
        value_n_nin                IN BOOLEAN := TRUE,
        value_tz_in                IN death_registry_det_hist.value_tz%TYPE DEFAULT NULL,
        value_tz_nin               IN BOOLEAN := TRUE,
        value_vc2_in               IN death_registry_det_hist.value_vc2%TYPE DEFAULT NULL,
        value_vc2_nin              IN BOOLEAN := TRUE,
        unit_measure_value_in      IN death_registry_det_hist.unit_measure_value%TYPE DEFAULT NULL,
        unit_measure_value_nin     IN BOOLEAN := TRUE,
        create_user_in             IN death_registry_det_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin            IN BOOLEAN := TRUE,
        create_time_in             IN death_registry_det_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin            IN BOOLEAN := TRUE,
        create_institution_in      IN death_registry_det_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin     IN BOOLEAN := TRUE,
        update_user_in             IN death_registry_det_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin            IN BOOLEAN := TRUE,
        update_time_in             IN death_registry_det_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin            IN BOOLEAN := TRUE,
        update_institution_in      IN death_registry_det_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin     IN BOOLEAN := TRUE,
        where_in                   IN VARCHAR2,
        handle_error_in            IN BOOLEAN := TRUE,
        rows_out                   IN OUT table_varchar
    );

    --Update any/all columns by dynamic WHERE
    -- If you pass NULL, then the current column value is set to itself
    PROCEDURE upd
    (
        id_death_registry_hist_in  IN death_registry_det_hist.id_death_registry_hist%TYPE DEFAULT NULL,
        id_death_registry_hist_nin IN BOOLEAN := TRUE,
        dt_death_registry_hist_in  IN death_registry_det_hist.dt_death_registry_hist%TYPE DEFAULT NULL,
        dt_death_registry_hist_nin IN BOOLEAN := TRUE,
        id_death_registry_in       IN death_registry_det_hist.id_death_registry%TYPE DEFAULT NULL,
        id_death_registry_nin      IN BOOLEAN := TRUE,
        id_ds_component_in         IN death_registry_det_hist.id_ds_component%TYPE DEFAULT NULL,
        id_ds_component_nin        IN BOOLEAN := TRUE,
        value_n_in                 IN death_registry_det_hist.value_n%TYPE DEFAULT NULL,
        value_n_nin                IN BOOLEAN := TRUE,
        value_tz_in                IN death_registry_det_hist.value_tz%TYPE DEFAULT NULL,
        value_tz_nin               IN BOOLEAN := TRUE,
        value_vc2_in               IN death_registry_det_hist.value_vc2%TYPE DEFAULT NULL,
        value_vc2_nin              IN BOOLEAN := TRUE,
        unit_measure_value_in      IN death_registry_det_hist.unit_measure_value%TYPE DEFAULT NULL,
        unit_measure_value_nin     IN BOOLEAN := TRUE,
        create_user_in             IN death_registry_det_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin            IN BOOLEAN := TRUE,
        create_time_in             IN death_registry_det_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin            IN BOOLEAN := TRUE,
        create_institution_in      IN death_registry_det_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin     IN BOOLEAN := TRUE,
        update_user_in             IN death_registry_det_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin            IN BOOLEAN := TRUE,
        update_time_in             IN death_registry_det_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin            IN BOOLEAN := TRUE,
        update_institution_in      IN death_registry_det_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin     IN BOOLEAN := TRUE,
        where_in                   IN VARCHAR2,
        handle_error_in            IN BOOLEAN := TRUE
    );

    --Update/insert with columns (with rows_out)
    PROCEDURE upd_ins
    (
        id_death_registry_det_hist_in IN death_registry_det_hist.id_death_registry_det_hist%TYPE,
        id_death_registry_hist_in     IN death_registry_det_hist.id_death_registry_hist%TYPE DEFAULT NULL,
        dt_death_registry_hist_in     IN death_registry_det_hist.dt_death_registry_hist%TYPE DEFAULT NULL,
        id_death_registry_in          IN death_registry_det_hist.id_death_registry%TYPE DEFAULT NULL,
        id_ds_component_in            IN death_registry_det_hist.id_ds_component%TYPE DEFAULT NULL,
        value_n_in                    IN death_registry_det_hist.value_n%TYPE DEFAULT NULL,
        value_tz_in                   IN death_registry_det_hist.value_tz%TYPE DEFAULT NULL,
        value_vc2_in                  IN death_registry_det_hist.value_vc2%TYPE DEFAULT NULL,
        unit_measure_value_in         IN death_registry_det_hist.unit_measure_value%TYPE DEFAULT NULL,
        create_user_in                IN death_registry_det_hist.create_user%TYPE DEFAULT NULL,
        create_time_in                IN death_registry_det_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in         IN death_registry_det_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in                IN death_registry_det_hist.update_user%TYPE DEFAULT NULL,
        update_time_in                IN death_registry_det_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in         IN death_registry_det_hist.update_institution%TYPE DEFAULT NULL,
        handle_error_in               IN BOOLEAN := TRUE,
        rows_out                      IN OUT table_varchar
    );

    --Update/insert with columns (without rows_out)
    PROCEDURE upd_ins
    (
        id_death_registry_det_hist_in IN death_registry_det_hist.id_death_registry_det_hist%TYPE,
        id_death_registry_hist_in     IN death_registry_det_hist.id_death_registry_hist%TYPE DEFAULT NULL,
        dt_death_registry_hist_in     IN death_registry_det_hist.dt_death_registry_hist%TYPE DEFAULT NULL,
        id_death_registry_in          IN death_registry_det_hist.id_death_registry%TYPE DEFAULT NULL,
        id_ds_component_in            IN death_registry_det_hist.id_ds_component%TYPE DEFAULT NULL,
        value_n_in                    IN death_registry_det_hist.value_n%TYPE DEFAULT NULL,
        value_tz_in                   IN death_registry_det_hist.value_tz%TYPE DEFAULT NULL,
        value_vc2_in                  IN death_registry_det_hist.value_vc2%TYPE DEFAULT NULL,
        unit_measure_value_in         IN death_registry_det_hist.unit_measure_value%TYPE DEFAULT NULL,
        create_user_in                IN death_registry_det_hist.create_user%TYPE DEFAULT NULL,
        create_time_in                IN death_registry_det_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in         IN death_registry_det_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in                IN death_registry_det_hist.update_user%TYPE DEFAULT NULL,
        update_time_in                IN death_registry_det_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in         IN death_registry_det_hist.update_institution%TYPE DEFAULT NULL,
        handle_error_in               IN BOOLEAN := TRUE
    );

    --Update record (with rows_out)
    PROCEDURE upd
    (
        rec_in          IN death_registry_det_hist%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    --Update record (without rows_out)
    PROCEDURE upd
    (
        rec_in          IN death_registry_det_hist%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    --Update collection (with rows_out)
    PROCEDURE upd
    (
        col_in            IN death_registry_det_hist_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    --Update collection (without rows_out)
    PROCEDURE upd
    (
        col_in            IN death_registry_det_hist_tc,
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
        id_death_registry_det_hist_in IN death_registry_det_hist.id_death_registry_det_hist%TYPE,
        handle_error_in               IN BOOLEAN := TRUE,
        rows_out                      OUT table_varchar
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_death_registry_det_hist_in IN death_registry_det_hist.id_death_registry_det_hist%TYPE,
        handle_error_in               IN BOOLEAN := TRUE
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

    -- Delete all rows for this DTHRD_H_DTHR_H_FK foreign key value
    PROCEDURE del_dthrd_h_dthr_h_fk
    (
        id_death_registry_hist_in IN death_registry_det_hist.id_death_registry_hist%TYPE,
        handle_error_in           IN BOOLEAN := TRUE,
        rows_out                  OUT table_varchar
    );

    -- Delete all rows for this DTHRD_H_DTHR_H_FK foreign key value
    PROCEDURE del_dthrd_h_dthr_h_fk
    (
        id_death_registry_hist_in IN death_registry_det_hist.id_death_registry_hist%TYPE,
        handle_error_in           IN BOOLEAN := TRUE
    );

    -- Initialize a record with default values for columns in the table (prc)
    PROCEDURE initrec(death_registry_det_hist_inout IN OUT death_registry_det_hist%ROWTYPE);

    -- Initialize a record with default values for columns in the table (fnc)
    FUNCTION initrec RETURN death_registry_det_hist%ROWTYPE;

    -- Get data rowid
    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN death_registry_det_hist_tc;

    -- Get data rowid pragma autonomous transaccion
    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN death_registry_det_hist_tc;

END ts_death_registry_det_hist;
/


