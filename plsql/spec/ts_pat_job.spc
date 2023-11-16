/*-- Last Change Revision: $Rev: 2029298 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:50:53 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE ts_pat_job
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Novembro 21, 2008 18:25:12
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "PAT_JOB"
    TYPE pat_job_tc IS TABLE OF pat_job%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE pat_job_ntt IS TABLE OF pat_job%ROWTYPE;
    TYPE pat_job_vat IS VARRAY(100) OF pat_job%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF pat_job%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF pat_job%ROWTYPE;
    TYPE vat IS VARRAY(100) OF pat_job%ROWTYPE;

    -- Column Collection based on column "ID_PAT_JOB"
    TYPE id_pat_job_cc IS TABLE OF pat_job.id_pat_job%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "LOCATION"
    TYPE location_cc IS TABLE OF pat_job.location%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_PATIENT"
    TYPE id_patient_cc IS TABLE OF pat_job.id_patient%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "YEAR_BEGIN"
    TYPE year_begin_cc IS TABLE OF pat_job.year_begin%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "YEAR_END"
    TYPE year_end_cc IS TABLE OF pat_job.year_end%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ACTIVITY_TYPE"
    TYPE activity_type_cc IS TABLE OF pat_job.activity_type%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "PROF_DISEASE_RISK"
    TYPE prof_disease_risk_cc IS TABLE OF pat_job.prof_disease_risk%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "NOTES"
    TYPE notes_cc IS TABLE OF pat_job.notes%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "NUM_WORKERS"
    TYPE num_workers_cc IS TABLE OF pat_job.num_workers%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "COMPANY"
    TYPE company_cc IS TABLE OF pat_job.company%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_STATUS"
    TYPE flg_status_cc IS TABLE OF pat_job.flg_status%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_OCCUPATION"
    TYPE id_occupation_cc IS TABLE OF pat_job.id_occupation%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_INSTITUTION"
    TYPE id_institution_cc IS TABLE OF pat_job.id_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "OCCUPATION_DESC"
    TYPE occupation_desc_cc IS TABLE OF pat_job.occupation_desc%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_PAT_JOB_TSTZ"
    TYPE dt_pat_job_tstz_cc IS TABLE OF pat_job.dt_pat_job_tstz%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_EPISODE"
    TYPE id_episode_cc IS TABLE OF pat_job.id_episode%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_pat_job_in        IN pat_job.id_pat_job%TYPE,
        location_in          IN pat_job.location%TYPE DEFAULT NULL,
        id_patient_in        IN pat_job.id_patient%TYPE DEFAULT NULL,
        year_begin_in        IN pat_job.year_begin%TYPE DEFAULT NULL,
        year_end_in          IN pat_job.year_end%TYPE DEFAULT NULL,
        activity_type_in     IN pat_job.activity_type%TYPE DEFAULT NULL,
        prof_disease_risk_in IN pat_job.prof_disease_risk%TYPE DEFAULT NULL,
        notes_in             IN pat_job.notes%TYPE DEFAULT NULL,
        num_workers_in       IN pat_job.num_workers%TYPE DEFAULT NULL,
        company_in           IN pat_job.company%TYPE DEFAULT NULL,
        flg_status_in        IN pat_job.flg_status%TYPE DEFAULT NULL,
        id_occupation_in     IN pat_job.id_occupation%TYPE DEFAULT NULL,
        id_institution_in    IN pat_job.id_institution%TYPE DEFAULT NULL,
        occupation_desc_in   IN pat_job.occupation_desc%TYPE DEFAULT NULL,
        dt_pat_job_tstz_in   IN pat_job.dt_pat_job_tstz%TYPE DEFAULT NULL,
        id_episode_in        IN pat_job.id_episode%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_pat_job_in        IN pat_job.id_pat_job%TYPE,
        location_in          IN pat_job.location%TYPE DEFAULT NULL,
        id_patient_in        IN pat_job.id_patient%TYPE DEFAULT NULL,
        year_begin_in        IN pat_job.year_begin%TYPE DEFAULT NULL,
        year_end_in          IN pat_job.year_end%TYPE DEFAULT NULL,
        activity_type_in     IN pat_job.activity_type%TYPE DEFAULT NULL,
        prof_disease_risk_in IN pat_job.prof_disease_risk%TYPE DEFAULT NULL,
        notes_in             IN pat_job.notes%TYPE DEFAULT NULL,
        num_workers_in       IN pat_job.num_workers%TYPE DEFAULT NULL,
        company_in           IN pat_job.company%TYPE DEFAULT NULL,
        flg_status_in        IN pat_job.flg_status%TYPE DEFAULT NULL,
        id_occupation_in     IN pat_job.id_occupation%TYPE DEFAULT NULL,
        id_institution_in    IN pat_job.id_institution%TYPE DEFAULT NULL,
        occupation_desc_in   IN pat_job.occupation_desc%TYPE DEFAULT NULL,
        dt_pat_job_tstz_in   IN pat_job.dt_pat_job_tstz%TYPE DEFAULT NULL,
        id_episode_in        IN pat_job.id_episode%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    -- Specify whether or not a primary key value should be generated.
    PROCEDURE ins
    (
        rec_in          IN pat_job%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN pat_job%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN pat_job_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN pat_job_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Return next primary key value using the named sequence.
    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN pat_job.id_pat_job%TYPE;

    -- Insert one row, generating hidden primary key using a sequence
    PROCEDURE ins
    (
        location_in          IN pat_job.location%TYPE DEFAULT NULL,
        id_patient_in        IN pat_job.id_patient%TYPE DEFAULT NULL,
        year_begin_in        IN pat_job.year_begin%TYPE DEFAULT NULL,
        year_end_in          IN pat_job.year_end%TYPE DEFAULT NULL,
        activity_type_in     IN pat_job.activity_type%TYPE DEFAULT NULL,
        prof_disease_risk_in IN pat_job.prof_disease_risk%TYPE DEFAULT NULL,
        notes_in             IN pat_job.notes%TYPE DEFAULT NULL,
        num_workers_in       IN pat_job.num_workers%TYPE DEFAULT NULL,
        company_in           IN pat_job.company%TYPE DEFAULT NULL,
        flg_status_in        IN pat_job.flg_status%TYPE DEFAULT NULL,
        id_occupation_in     IN pat_job.id_occupation%TYPE DEFAULT NULL,
        id_institution_in    IN pat_job.id_institution%TYPE DEFAULT NULL,
        occupation_desc_in   IN pat_job.occupation_desc%TYPE DEFAULT NULL,
        dt_pat_job_tstz_in   IN pat_job.dt_pat_job_tstz%TYPE DEFAULT NULL,
        id_episode_in        IN pat_job.id_episode%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        location_in          IN pat_job.location%TYPE DEFAULT NULL,
        id_patient_in        IN pat_job.id_patient%TYPE DEFAULT NULL,
        year_begin_in        IN pat_job.year_begin%TYPE DEFAULT NULL,
        year_end_in          IN pat_job.year_end%TYPE DEFAULT NULL,
        activity_type_in     IN pat_job.activity_type%TYPE DEFAULT NULL,
        prof_disease_risk_in IN pat_job.prof_disease_risk%TYPE DEFAULT NULL,
        notes_in             IN pat_job.notes%TYPE DEFAULT NULL,
        num_workers_in       IN pat_job.num_workers%TYPE DEFAULT NULL,
        company_in           IN pat_job.company%TYPE DEFAULT NULL,
        flg_status_in        IN pat_job.flg_status%TYPE DEFAULT NULL,
        id_occupation_in     IN pat_job.id_occupation%TYPE DEFAULT NULL,
        id_institution_in    IN pat_job.id_institution%TYPE DEFAULT NULL,
        occupation_desc_in   IN pat_job.occupation_desc%TYPE DEFAULT NULL,
        dt_pat_job_tstz_in   IN pat_job.dt_pat_job_tstz%TYPE DEFAULT NULL,
        id_episode_in        IN pat_job.id_episode%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row, returning primary key generated by sequence
    PROCEDURE ins
    (
        location_in          IN pat_job.location%TYPE DEFAULT NULL,
        id_patient_in        IN pat_job.id_patient%TYPE DEFAULT NULL,
        year_begin_in        IN pat_job.year_begin%TYPE DEFAULT NULL,
        year_end_in          IN pat_job.year_end%TYPE DEFAULT NULL,
        activity_type_in     IN pat_job.activity_type%TYPE DEFAULT NULL,
        prof_disease_risk_in IN pat_job.prof_disease_risk%TYPE DEFAULT NULL,
        notes_in             IN pat_job.notes%TYPE DEFAULT NULL,
        num_workers_in       IN pat_job.num_workers%TYPE DEFAULT NULL,
        company_in           IN pat_job.company%TYPE DEFAULT NULL,
        flg_status_in        IN pat_job.flg_status%TYPE DEFAULT NULL,
        id_occupation_in     IN pat_job.id_occupation%TYPE DEFAULT NULL,
        id_institution_in    IN pat_job.id_institution%TYPE DEFAULT NULL,
        occupation_desc_in   IN pat_job.occupation_desc%TYPE DEFAULT NULL,
        dt_pat_job_tstz_in   IN pat_job.dt_pat_job_tstz%TYPE DEFAULT NULL,
        id_episode_in        IN pat_job.id_episode%TYPE DEFAULT NULL,
        id_pat_job_out       IN OUT pat_job.id_pat_job%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        location_in          IN pat_job.location%TYPE DEFAULT NULL,
        id_patient_in        IN pat_job.id_patient%TYPE DEFAULT NULL,
        year_begin_in        IN pat_job.year_begin%TYPE DEFAULT NULL,
        year_end_in          IN pat_job.year_end%TYPE DEFAULT NULL,
        activity_type_in     IN pat_job.activity_type%TYPE DEFAULT NULL,
        prof_disease_risk_in IN pat_job.prof_disease_risk%TYPE DEFAULT NULL,
        notes_in             IN pat_job.notes%TYPE DEFAULT NULL,
        num_workers_in       IN pat_job.num_workers%TYPE DEFAULT NULL,
        company_in           IN pat_job.company%TYPE DEFAULT NULL,
        flg_status_in        IN pat_job.flg_status%TYPE DEFAULT NULL,
        id_occupation_in     IN pat_job.id_occupation%TYPE DEFAULT NULL,
        id_institution_in    IN pat_job.id_institution%TYPE DEFAULT NULL,
        occupation_desc_in   IN pat_job.occupation_desc%TYPE DEFAULT NULL,
        dt_pat_job_tstz_in   IN pat_job.dt_pat_job_tstz%TYPE DEFAULT NULL,
        id_episode_in        IN pat_job.id_episode%TYPE DEFAULT NULL,
        id_pat_job_out       IN OUT pat_job.id_pat_job%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row with function, return generated primary key
    FUNCTION ins
    (
        location_in          IN pat_job.location%TYPE DEFAULT NULL,
        id_patient_in        IN pat_job.id_patient%TYPE DEFAULT NULL,
        year_begin_in        IN pat_job.year_begin%TYPE DEFAULT NULL,
        year_end_in          IN pat_job.year_end%TYPE DEFAULT NULL,
        activity_type_in     IN pat_job.activity_type%TYPE DEFAULT NULL,
        prof_disease_risk_in IN pat_job.prof_disease_risk%TYPE DEFAULT NULL,
        notes_in             IN pat_job.notes%TYPE DEFAULT NULL,
        num_workers_in       IN pat_job.num_workers%TYPE DEFAULT NULL,
        company_in           IN pat_job.company%TYPE DEFAULT NULL,
        flg_status_in        IN pat_job.flg_status%TYPE DEFAULT NULL,
        id_occupation_in     IN pat_job.id_occupation%TYPE DEFAULT NULL,
        id_institution_in    IN pat_job.id_institution%TYPE DEFAULT NULL,
        occupation_desc_in   IN pat_job.occupation_desc%TYPE DEFAULT NULL,
        dt_pat_job_tstz_in   IN pat_job.dt_pat_job_tstz%TYPE DEFAULT NULL,
        id_episode_in        IN pat_job.id_episode%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    ) RETURN pat_job.id_pat_job%TYPE;

    FUNCTION ins
    (
        location_in          IN pat_job.location%TYPE DEFAULT NULL,
        id_patient_in        IN pat_job.id_patient%TYPE DEFAULT NULL,
        year_begin_in        IN pat_job.year_begin%TYPE DEFAULT NULL,
        year_end_in          IN pat_job.year_end%TYPE DEFAULT NULL,
        activity_type_in     IN pat_job.activity_type%TYPE DEFAULT NULL,
        prof_disease_risk_in IN pat_job.prof_disease_risk%TYPE DEFAULT NULL,
        notes_in             IN pat_job.notes%TYPE DEFAULT NULL,
        num_workers_in       IN pat_job.num_workers%TYPE DEFAULT NULL,
        company_in           IN pat_job.company%TYPE DEFAULT NULL,
        flg_status_in        IN pat_job.flg_status%TYPE DEFAULT NULL,
        id_occupation_in     IN pat_job.id_occupation%TYPE DEFAULT NULL,
        id_institution_in    IN pat_job.id_institution%TYPE DEFAULT NULL,
        occupation_desc_in   IN pat_job.occupation_desc%TYPE DEFAULT NULL,
        dt_pat_job_tstz_in   IN pat_job.dt_pat_job_tstz%TYPE DEFAULT NULL,
        id_episode_in        IN pat_job.id_episode%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    ) RETURN pat_job.id_pat_job%TYPE;

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        id_pat_job_in         IN pat_job.id_pat_job%TYPE,
        location_in           IN pat_job.location%TYPE DEFAULT NULL,
        location_nin          IN BOOLEAN := TRUE,
        id_patient_in         IN pat_job.id_patient%TYPE DEFAULT NULL,
        id_patient_nin        IN BOOLEAN := TRUE,
        year_begin_in         IN pat_job.year_begin%TYPE DEFAULT NULL,
        year_begin_nin        IN BOOLEAN := TRUE,
        year_end_in           IN pat_job.year_end%TYPE DEFAULT NULL,
        year_end_nin          IN BOOLEAN := TRUE,
        activity_type_in      IN pat_job.activity_type%TYPE DEFAULT NULL,
        activity_type_nin     IN BOOLEAN := TRUE,
        prof_disease_risk_in  IN pat_job.prof_disease_risk%TYPE DEFAULT NULL,
        prof_disease_risk_nin IN BOOLEAN := TRUE,
        notes_in              IN pat_job.notes%TYPE DEFAULT NULL,
        notes_nin             IN BOOLEAN := TRUE,
        num_workers_in        IN pat_job.num_workers%TYPE DEFAULT NULL,
        num_workers_nin       IN BOOLEAN := TRUE,
        company_in            IN pat_job.company%TYPE DEFAULT NULL,
        company_nin           IN BOOLEAN := TRUE,
        flg_status_in         IN pat_job.flg_status%TYPE DEFAULT NULL,
        flg_status_nin        IN BOOLEAN := TRUE,
        id_occupation_in      IN pat_job.id_occupation%TYPE DEFAULT NULL,
        id_occupation_nin     IN BOOLEAN := TRUE,
        id_institution_in     IN pat_job.id_institution%TYPE DEFAULT NULL,
        id_institution_nin    IN BOOLEAN := TRUE,
        occupation_desc_in    IN pat_job.occupation_desc%TYPE DEFAULT NULL,
        occupation_desc_nin   IN BOOLEAN := TRUE,
        dt_pat_job_tstz_in    IN pat_job.dt_pat_job_tstz%TYPE DEFAULT NULL,
        dt_pat_job_tstz_nin   IN BOOLEAN := TRUE,
        id_episode_in         IN pat_job.id_episode%TYPE DEFAULT NULL,
        id_episode_nin        IN BOOLEAN := TRUE,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_pat_job_in         IN pat_job.id_pat_job%TYPE,
        location_in           IN pat_job.location%TYPE DEFAULT NULL,
        location_nin          IN BOOLEAN := TRUE,
        id_patient_in         IN pat_job.id_patient%TYPE DEFAULT NULL,
        id_patient_nin        IN BOOLEAN := TRUE,
        year_begin_in         IN pat_job.year_begin%TYPE DEFAULT NULL,
        year_begin_nin        IN BOOLEAN := TRUE,
        year_end_in           IN pat_job.year_end%TYPE DEFAULT NULL,
        year_end_nin          IN BOOLEAN := TRUE,
        activity_type_in      IN pat_job.activity_type%TYPE DEFAULT NULL,
        activity_type_nin     IN BOOLEAN := TRUE,
        prof_disease_risk_in  IN pat_job.prof_disease_risk%TYPE DEFAULT NULL,
        prof_disease_risk_nin IN BOOLEAN := TRUE,
        notes_in              IN pat_job.notes%TYPE DEFAULT NULL,
        notes_nin             IN BOOLEAN := TRUE,
        num_workers_in        IN pat_job.num_workers%TYPE DEFAULT NULL,
        num_workers_nin       IN BOOLEAN := TRUE,
        company_in            IN pat_job.company%TYPE DEFAULT NULL,
        company_nin           IN BOOLEAN := TRUE,
        flg_status_in         IN pat_job.flg_status%TYPE DEFAULT NULL,
        flg_status_nin        IN BOOLEAN := TRUE,
        id_occupation_in      IN pat_job.id_occupation%TYPE DEFAULT NULL,
        id_occupation_nin     IN BOOLEAN := TRUE,
        id_institution_in     IN pat_job.id_institution%TYPE DEFAULT NULL,
        id_institution_nin    IN BOOLEAN := TRUE,
        occupation_desc_in    IN pat_job.occupation_desc%TYPE DEFAULT NULL,
        occupation_desc_nin   IN BOOLEAN := TRUE,
        dt_pat_job_tstz_in    IN pat_job.dt_pat_job_tstz%TYPE DEFAULT NULL,
        dt_pat_job_tstz_nin   IN BOOLEAN := TRUE,
        id_episode_in         IN pat_job.id_episode%TYPE DEFAULT NULL,
        id_episode_nin        IN BOOLEAN := TRUE,
        handle_error_in       IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        location_in           IN pat_job.location%TYPE DEFAULT NULL,
        location_nin          IN BOOLEAN := TRUE,
        id_patient_in         IN pat_job.id_patient%TYPE DEFAULT NULL,
        id_patient_nin        IN BOOLEAN := TRUE,
        year_begin_in         IN pat_job.year_begin%TYPE DEFAULT NULL,
        year_begin_nin        IN BOOLEAN := TRUE,
        year_end_in           IN pat_job.year_end%TYPE DEFAULT NULL,
        year_end_nin          IN BOOLEAN := TRUE,
        activity_type_in      IN pat_job.activity_type%TYPE DEFAULT NULL,
        activity_type_nin     IN BOOLEAN := TRUE,
        prof_disease_risk_in  IN pat_job.prof_disease_risk%TYPE DEFAULT NULL,
        prof_disease_risk_nin IN BOOLEAN := TRUE,
        notes_in              IN pat_job.notes%TYPE DEFAULT NULL,
        notes_nin             IN BOOLEAN := TRUE,
        num_workers_in        IN pat_job.num_workers%TYPE DEFAULT NULL,
        num_workers_nin       IN BOOLEAN := TRUE,
        company_in            IN pat_job.company%TYPE DEFAULT NULL,
        company_nin           IN BOOLEAN := TRUE,
        flg_status_in         IN pat_job.flg_status%TYPE DEFAULT NULL,
        flg_status_nin        IN BOOLEAN := TRUE,
        id_occupation_in      IN pat_job.id_occupation%TYPE DEFAULT NULL,
        id_occupation_nin     IN BOOLEAN := TRUE,
        id_institution_in     IN pat_job.id_institution%TYPE DEFAULT NULL,
        id_institution_nin    IN BOOLEAN := TRUE,
        occupation_desc_in    IN pat_job.occupation_desc%TYPE DEFAULT NULL,
        occupation_desc_nin   IN BOOLEAN := TRUE,
        dt_pat_job_tstz_in    IN pat_job.dt_pat_job_tstz%TYPE DEFAULT NULL,
        dt_pat_job_tstz_nin   IN BOOLEAN := TRUE,
        id_episode_in         IN pat_job.id_episode%TYPE DEFAULT NULL,
        id_episode_nin        IN BOOLEAN := TRUE,
        where_in              VARCHAR2 DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              IN OUT table_varchar
    );

    PROCEDURE upd
    (
        location_in           IN pat_job.location%TYPE DEFAULT NULL,
        location_nin          IN BOOLEAN := TRUE,
        id_patient_in         IN pat_job.id_patient%TYPE DEFAULT NULL,
        id_patient_nin        IN BOOLEAN := TRUE,
        year_begin_in         IN pat_job.year_begin%TYPE DEFAULT NULL,
        year_begin_nin        IN BOOLEAN := TRUE,
        year_end_in           IN pat_job.year_end%TYPE DEFAULT NULL,
        year_end_nin          IN BOOLEAN := TRUE,
        activity_type_in      IN pat_job.activity_type%TYPE DEFAULT NULL,
        activity_type_nin     IN BOOLEAN := TRUE,
        prof_disease_risk_in  IN pat_job.prof_disease_risk%TYPE DEFAULT NULL,
        prof_disease_risk_nin IN BOOLEAN := TRUE,
        notes_in              IN pat_job.notes%TYPE DEFAULT NULL,
        notes_nin             IN BOOLEAN := TRUE,
        num_workers_in        IN pat_job.num_workers%TYPE DEFAULT NULL,
        num_workers_nin       IN BOOLEAN := TRUE,
        company_in            IN pat_job.company%TYPE DEFAULT NULL,
        company_nin           IN BOOLEAN := TRUE,
        flg_status_in         IN pat_job.flg_status%TYPE DEFAULT NULL,
        flg_status_nin        IN BOOLEAN := TRUE,
        id_occupation_in      IN pat_job.id_occupation%TYPE DEFAULT NULL,
        id_occupation_nin     IN BOOLEAN := TRUE,
        id_institution_in     IN pat_job.id_institution%TYPE DEFAULT NULL,
        id_institution_nin    IN BOOLEAN := TRUE,
        occupation_desc_in    IN pat_job.occupation_desc%TYPE DEFAULT NULL,
        occupation_desc_nin   IN BOOLEAN := TRUE,
        dt_pat_job_tstz_in    IN pat_job.dt_pat_job_tstz%TYPE DEFAULT NULL,
        dt_pat_job_tstz_nin   IN BOOLEAN := TRUE,
        id_episode_in         IN pat_job.id_episode%TYPE DEFAULT NULL,
        id_episode_nin        IN BOOLEAN := TRUE,
        where_in              VARCHAR2 DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_pat_job_in        IN pat_job.id_pat_job%TYPE,
        location_in          IN pat_job.location%TYPE DEFAULT NULL,
        id_patient_in        IN pat_job.id_patient%TYPE DEFAULT NULL,
        year_begin_in        IN pat_job.year_begin%TYPE DEFAULT NULL,
        year_end_in          IN pat_job.year_end%TYPE DEFAULT NULL,
        activity_type_in     IN pat_job.activity_type%TYPE DEFAULT NULL,
        prof_disease_risk_in IN pat_job.prof_disease_risk%TYPE DEFAULT NULL,
        notes_in             IN pat_job.notes%TYPE DEFAULT NULL,
        num_workers_in       IN pat_job.num_workers%TYPE DEFAULT NULL,
        company_in           IN pat_job.company%TYPE DEFAULT NULL,
        flg_status_in        IN pat_job.flg_status%TYPE DEFAULT NULL,
        id_occupation_in     IN pat_job.id_occupation%TYPE DEFAULT NULL,
        id_institution_in    IN pat_job.id_institution%TYPE DEFAULT NULL,
        occupation_desc_in   IN pat_job.occupation_desc%TYPE DEFAULT NULL,
        dt_pat_job_tstz_in   IN pat_job.dt_pat_job_tstz%TYPE DEFAULT NULL,
        id_episode_in        IN pat_job.id_episode%TYPE DEFAULT NULL,
        handle_error_in      IN BOOLEAN := TRUE,
        rows_out             OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_pat_job_in        IN pat_job.id_pat_job%TYPE,
        location_in          IN pat_job.location%TYPE DEFAULT NULL,
        id_patient_in        IN pat_job.id_patient%TYPE DEFAULT NULL,
        year_begin_in        IN pat_job.year_begin%TYPE DEFAULT NULL,
        year_end_in          IN pat_job.year_end%TYPE DEFAULT NULL,
        activity_type_in     IN pat_job.activity_type%TYPE DEFAULT NULL,
        prof_disease_risk_in IN pat_job.prof_disease_risk%TYPE DEFAULT NULL,
        notes_in             IN pat_job.notes%TYPE DEFAULT NULL,
        num_workers_in       IN pat_job.num_workers%TYPE DEFAULT NULL,
        company_in           IN pat_job.company%TYPE DEFAULT NULL,
        flg_status_in        IN pat_job.flg_status%TYPE DEFAULT NULL,
        id_occupation_in     IN pat_job.id_occupation%TYPE DEFAULT NULL,
        id_institution_in    IN pat_job.id_institution%TYPE DEFAULT NULL,
        occupation_desc_in   IN pat_job.occupation_desc%TYPE DEFAULT NULL,
        dt_pat_job_tstz_in   IN pat_job.dt_pat_job_tstz%TYPE DEFAULT NULL,
        id_episode_in        IN pat_job.id_episode%TYPE DEFAULT NULL,
        handle_error_in      IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN pat_job%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN pat_job%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN pat_job_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN pat_job_tc,
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
        id_pat_job_in   IN pat_job.id_pat_job%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_pat_job_in   IN pat_job.id_pat_job%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for primary key column ID_PAT_JOB
    PROCEDURE del_id_pat_job
    (
        id_pat_job_in   IN pat_job.id_pat_job%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_PAT_JOB
    PROCEDURE del_id_pat_job
    (
        id_pat_job_in   IN pat_job.id_pat_job%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this PTJOB_EPIS_FK foreign key value
    PROCEDURE del_ptjob_epis_fk
    (
        id_episode_in   IN pat_job.id_episode%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PTJOB_EPIS_FK foreign key value
    PROCEDURE del_ptjob_epis_fk
    (
        id_episode_in   IN pat_job.id_episode%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this PTJOB_INST_FK foreign key value
    PROCEDURE del_ptjob_inst_fk
    (
        id_institution_in IN pat_job.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PTJOB_INST_FK foreign key value
    PROCEDURE del_ptjob_inst_fk
    (
        id_institution_in IN pat_job.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows for this PTJOB_OCC_FK foreign key value
    PROCEDURE del_ptjob_occ_fk
    (
        id_occupation_in IN pat_job.id_occupation%TYPE,
        handle_error_in  IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PTJOB_OCC_FK foreign key value
    PROCEDURE del_ptjob_occ_fk
    (
        id_occupation_in IN pat_job.id_occupation%TYPE,
        handle_error_in  IN BOOLEAN := TRUE,
        rows_out         OUT table_varchar
    );

    -- Delete all rows for this PTJOB_PAT_FK foreign key value
    PROCEDURE del_ptjob_pat_fk
    (
        id_patient_in   IN pat_job.id_patient%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PTJOB_PAT_FK foreign key value
    PROCEDURE del_ptjob_pat_fk
    (
        id_patient_in   IN pat_job.id_patient%TYPE,
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
    PROCEDURE initrec(pat_job_inout IN OUT pat_job%ROWTYPE);

    FUNCTION initrec RETURN pat_job%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN pat_job_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN pat_job_tc;

END ts_pat_job;
/
