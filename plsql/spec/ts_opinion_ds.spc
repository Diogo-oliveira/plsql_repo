/*-- Last Change Revision: $Rev: 9999999 $*/
/*-- Last Change by: $Author: arch.tech $*/
/*-- Date of last change: $Date: 2020-20-01 15:19:53 +0100) $*/
CREATE OR REPLACE PACKAGE ts_opinion_ds
/*
| Generated by or retrieved - DO NOT MODIFY!
| Created On: 2020-01-20 15:19:53
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on opinion_ds
    TYPE opinion_ds_tc IS TABLE OF opinion_ds%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE opinion_ds_ntt IS TABLE OF opinion_ds%ROWTYPE;
    TYPE opinion_ds_vat IS VARRAY(100) OF opinion_ds%ROWTYPE;

    -- Column Collection based on column ID_OPINION_DS
    TYPE id_opinion_ds_cc IS TABLE OF opinion_ds.id_opinion_ds%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_OPINION
    TYPE id_opinion_cc IS TABLE OF opinion_ds.id_opinion%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column DT_PROBLEM_TSTZ
    TYPE dt_problem_tstz_cc IS TABLE OF opinion_ds.dt_problem_tstz%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_DS_CMPT_MKT_REL
    TYPE id_ds_cmpt_mkt_rel_cc IS TABLE OF opinion_ds.id_ds_cmpt_mkt_rel%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column VALUE
    TYPE value_cc IS TABLE OF opinion_ds.value%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column VALUE_CLOB
    TYPE value_clob_cc IS TABLE OF opinion_ds.value_clob%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_USER
    TYPE create_user_cc IS TABLE OF opinion_ds.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_TIME
    TYPE create_time_cc IS TABLE OF opinion_ds.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_INSTITUTION
    TYPE create_institution_cc IS TABLE OF opinion_ds.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_USER
    TYPE update_user_cc IS TABLE OF opinion_ds.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_TIME
    TYPE update_time_cc IS TABLE OF opinion_ds.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_INSTITUTION
    TYPE update_institution_cc IS TABLE OF opinion_ds.update_institution%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present (with rows_out)
    PROCEDURE ins
    (
        id_opinion_ds_in      IN opinion_ds.id_opinion_ds%TYPE,
        id_opinion_in         IN opinion_ds.id_opinion%TYPE DEFAULT NULL,
        dt_problem_tstz_in    IN opinion_ds.dt_problem_tstz%TYPE DEFAULT NULL,
        id_ds_cmpt_mkt_rel_in IN opinion_ds.id_ds_cmpt_mkt_rel%TYPE DEFAULT NULL,
        value_in              IN opinion_ds.value%TYPE DEFAULT NULL,
        value_clob_in         IN opinion_ds.value_clob%TYPE DEFAULT NULL,
        create_user_in        IN opinion_ds.create_user%TYPE DEFAULT NULL,
        create_time_in        IN opinion_ds.create_time%TYPE DEFAULT NULL,
        create_institution_in IN opinion_ds.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN opinion_ds.update_user%TYPE DEFAULT NULL,
        update_time_in        IN opinion_ds.update_time%TYPE DEFAULT NULL,
        update_institution_in IN opinion_ds.update_institution%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
    );

    -- Insert one row, providing primary key if present (without rows_out)
    PROCEDURE ins
    (
        id_opinion_ds_in      IN opinion_ds.id_opinion_ds%TYPE,
        id_opinion_in         IN opinion_ds.id_opinion%TYPE DEFAULT NULL,
        dt_problem_tstz_in    IN opinion_ds.dt_problem_tstz%TYPE DEFAULT NULL,
        id_ds_cmpt_mkt_rel_in IN opinion_ds.id_ds_cmpt_mkt_rel%TYPE DEFAULT NULL,
        value_in              IN opinion_ds.value%TYPE DEFAULT NULL,
        value_clob_in         IN opinion_ds.value_clob%TYPE DEFAULT NULL,
        create_user_in        IN opinion_ds.create_user%TYPE DEFAULT NULL,
        create_time_in        IN opinion_ds.create_time%TYPE DEFAULT NULL,
        create_institution_in IN opinion_ds.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN opinion_ds.update_user%TYPE DEFAULT NULL,
        update_time_in        IN opinion_ds.update_time%TYPE DEFAULT NULL,
        update_institution_in IN opinion_ds.update_institution%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record
    -- Specify whether or not a primary key value should be generated
    PROCEDURE ins
    (
        rec_in          IN opinion_ds%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert a row based on a record
    -- Specify whether or not a primary key value should be generated
    PROCEDURE ins
    (
        rec_in          IN opinion_ds%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers
    PROCEDURE ins
    (
        rows_in         IN opinion_ds_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers
    PROCEDURE ins
    (
        rows_in         IN opinion_ds_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Return next primary key value using the named sequence
    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN opinion_ds.id_opinion_ds%TYPE;

    -- Insert one row, generating hidden primary key using a sequence
    PROCEDURE ins
    (
        id_opinion_in         IN opinion_ds.id_opinion%TYPE DEFAULT NULL,
        dt_problem_tstz_in    IN opinion_ds.dt_problem_tstz%TYPE DEFAULT NULL,
        id_ds_cmpt_mkt_rel_in IN opinion_ds.id_ds_cmpt_mkt_rel%TYPE DEFAULT NULL,
        value_in              IN opinion_ds.value%TYPE DEFAULT NULL,
        value_clob_in         IN opinion_ds.value_clob%TYPE DEFAULT NULL,
        create_user_in        IN opinion_ds.create_user%TYPE DEFAULT NULL,
        create_time_in        IN opinion_ds.create_time%TYPE DEFAULT NULL,
        create_institution_in IN opinion_ds.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN opinion_ds.update_user%TYPE DEFAULT NULL,
        update_time_in        IN opinion_ds.update_time%TYPE DEFAULT NULL,
        update_institution_in IN opinion_ds.update_institution%TYPE DEFAULT NULL,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert one row, generating hidden primary key using a sequence
    PROCEDURE ins
    (
        id_opinion_in         IN opinion_ds.id_opinion%TYPE DEFAULT NULL,
        dt_problem_tstz_in    IN opinion_ds.dt_problem_tstz%TYPE DEFAULT NULL,
        id_ds_cmpt_mkt_rel_in IN opinion_ds.id_ds_cmpt_mkt_rel%TYPE DEFAULT NULL,
        value_in              IN opinion_ds.value%TYPE DEFAULT NULL,
        value_clob_in         IN opinion_ds.value_clob%TYPE DEFAULT NULL,
        create_user_in        IN opinion_ds.create_user%TYPE DEFAULT NULL,
        create_time_in        IN opinion_ds.create_time%TYPE DEFAULT NULL,
        create_institution_in IN opinion_ds.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN opinion_ds.update_user%TYPE DEFAULT NULL,
        update_time_in        IN opinion_ds.update_time%TYPE DEFAULT NULL,
        update_institution_in IN opinion_ds.update_institution%TYPE DEFAULT NULL,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row, returning primary key generated by sequence
    PROCEDURE ins
    (
        id_opinion_in         IN opinion_ds.id_opinion%TYPE DEFAULT NULL,
        dt_problem_tstz_in    IN opinion_ds.dt_problem_tstz%TYPE DEFAULT NULL,
        id_ds_cmpt_mkt_rel_in IN opinion_ds.id_ds_cmpt_mkt_rel%TYPE DEFAULT NULL,
        value_in              IN opinion_ds.value%TYPE DEFAULT NULL,
        value_clob_in         IN opinion_ds.value_clob%TYPE DEFAULT NULL,
        create_user_in        IN opinion_ds.create_user%TYPE DEFAULT NULL,
        create_time_in        IN opinion_ds.create_time%TYPE DEFAULT NULL,
        create_institution_in IN opinion_ds.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN opinion_ds.update_user%TYPE DEFAULT NULL,
        update_time_in        IN opinion_ds.update_time%TYPE DEFAULT NULL,
        update_institution_in IN opinion_ds.update_institution%TYPE DEFAULT NULL,
        id_opinion_ds_out     IN OUT opinion_ds.id_opinion_ds%TYPE,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert one row, returning primary key generated by sequence
    PROCEDURE ins
    (
        id_opinion_in         IN opinion_ds.id_opinion%TYPE DEFAULT NULL,
        dt_problem_tstz_in    IN opinion_ds.dt_problem_tstz%TYPE DEFAULT NULL,
        id_ds_cmpt_mkt_rel_in IN opinion_ds.id_ds_cmpt_mkt_rel%TYPE DEFAULT NULL,
        value_in              IN opinion_ds.value%TYPE DEFAULT NULL,
        value_clob_in         IN opinion_ds.value_clob%TYPE DEFAULT NULL,
        create_user_in        IN opinion_ds.create_user%TYPE DEFAULT NULL,
        create_time_in        IN opinion_ds.create_time%TYPE DEFAULT NULL,
        create_institution_in IN opinion_ds.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN opinion_ds.update_user%TYPE DEFAULT NULL,
        update_time_in        IN opinion_ds.update_time%TYPE DEFAULT NULL,
        update_institution_in IN opinion_ds.update_institution%TYPE DEFAULT NULL,
        id_opinion_ds_out     IN OUT opinion_ds.id_opinion_ds%TYPE,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row with function, return generated primary key
    FUNCTION ins
    (
        id_opinion_in         IN opinion_ds.id_opinion%TYPE DEFAULT NULL,
        dt_problem_tstz_in    IN opinion_ds.dt_problem_tstz%TYPE DEFAULT NULL,
        id_ds_cmpt_mkt_rel_in IN opinion_ds.id_ds_cmpt_mkt_rel%TYPE DEFAULT NULL,
        value_in              IN opinion_ds.value%TYPE DEFAULT NULL,
        value_clob_in         IN opinion_ds.value_clob%TYPE DEFAULT NULL,
        create_user_in        IN opinion_ds.create_user%TYPE DEFAULT NULL,
        create_time_in        IN opinion_ds.create_time%TYPE DEFAULT NULL,
        create_institution_in IN opinion_ds.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN opinion_ds.update_user%TYPE DEFAULT NULL,
        update_time_in        IN opinion_ds.update_time%TYPE DEFAULT NULL,
        update_institution_in IN opinion_ds.update_institution%TYPE DEFAULT NULL,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    ) RETURN opinion_ds.id_opinion_ds%TYPE;

    -- Insert one row with function, return generated primary key
    FUNCTION ins
    (
        id_opinion_in         IN opinion_ds.id_opinion%TYPE DEFAULT NULL,
        dt_problem_tstz_in    IN opinion_ds.dt_problem_tstz%TYPE DEFAULT NULL,
        id_ds_cmpt_mkt_rel_in IN opinion_ds.id_ds_cmpt_mkt_rel%TYPE DEFAULT NULL,
        value_in              IN opinion_ds.value%TYPE DEFAULT NULL,
        value_clob_in         IN opinion_ds.value_clob%TYPE DEFAULT NULL,
        create_user_in        IN opinion_ds.create_user%TYPE DEFAULT NULL,
        create_time_in        IN opinion_ds.create_time%TYPE DEFAULT NULL,
        create_institution_in IN opinion_ds.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN opinion_ds.update_user%TYPE DEFAULT NULL,
        update_time_in        IN opinion_ds.update_time%TYPE DEFAULT NULL,
        update_institution_in IN opinion_ds.update_institution%TYPE DEFAULT NULL,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE
    ) RETURN opinion_ds.id_opinion_ds%TYPE;

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.
    PROCEDURE upd
    (
        id_opinion_ds_in       IN opinion_ds.id_opinion_ds%TYPE,
        id_opinion_in          IN opinion_ds.id_opinion%TYPE DEFAULT NULL,
        id_opinion_nin         IN BOOLEAN := TRUE,
        dt_problem_tstz_in     IN opinion_ds.dt_problem_tstz%TYPE DEFAULT NULL,
        dt_problem_tstz_nin    IN BOOLEAN := TRUE,
        id_ds_cmpt_mkt_rel_in  IN opinion_ds.id_ds_cmpt_mkt_rel%TYPE DEFAULT NULL,
        id_ds_cmpt_mkt_rel_nin IN BOOLEAN := TRUE,
        value_in               IN opinion_ds.value%TYPE DEFAULT NULL,
        value_nin              IN BOOLEAN := TRUE,
        value_clob_in          IN opinion_ds.value_clob%TYPE DEFAULT NULL,
        value_clob_nin         IN BOOLEAN := TRUE,
        create_user_in         IN opinion_ds.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN opinion_ds.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN opinion_ds.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN opinion_ds.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN opinion_ds.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN opinion_ds.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.
    PROCEDURE upd
    (
        id_opinion_ds_in       IN opinion_ds.id_opinion_ds%TYPE,
        id_opinion_in          IN opinion_ds.id_opinion%TYPE DEFAULT NULL,
        id_opinion_nin         IN BOOLEAN := TRUE,
        dt_problem_tstz_in     IN opinion_ds.dt_problem_tstz%TYPE DEFAULT NULL,
        dt_problem_tstz_nin    IN BOOLEAN := TRUE,
        id_ds_cmpt_mkt_rel_in  IN opinion_ds.id_ds_cmpt_mkt_rel%TYPE DEFAULT NULL,
        id_ds_cmpt_mkt_rel_nin IN BOOLEAN := TRUE,
        value_in               IN opinion_ds.value%TYPE DEFAULT NULL,
        value_nin              IN BOOLEAN := TRUE,
        value_clob_in          IN opinion_ds.value_clob%TYPE DEFAULT NULL,
        value_clob_nin         IN BOOLEAN := TRUE,
        create_user_in         IN opinion_ds.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN opinion_ds.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN opinion_ds.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN opinion_ds.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN opinion_ds.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN opinion_ds.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    --Update any/all columns by dynamic WHERE
    -- If you pass NULL, then the current column value is set to itself
    PROCEDURE upd
    (
        id_opinion_in          IN opinion_ds.id_opinion%TYPE DEFAULT NULL,
        id_opinion_nin         IN BOOLEAN := TRUE,
        dt_problem_tstz_in     IN opinion_ds.dt_problem_tstz%TYPE DEFAULT NULL,
        dt_problem_tstz_nin    IN BOOLEAN := TRUE,
        id_ds_cmpt_mkt_rel_in  IN opinion_ds.id_ds_cmpt_mkt_rel%TYPE DEFAULT NULL,
        id_ds_cmpt_mkt_rel_nin IN BOOLEAN := TRUE,
        value_in               IN opinion_ds.value%TYPE DEFAULT NULL,
        value_nin              IN BOOLEAN := TRUE,
        value_clob_in          IN opinion_ds.value_clob%TYPE DEFAULT NULL,
        value_clob_nin         IN BOOLEAN := TRUE,
        create_user_in         IN opinion_ds.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN opinion_ds.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN opinion_ds.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN opinion_ds.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN opinion_ds.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN opinion_ds.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        where_in               IN VARCHAR2,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    --Update any/all columns by dynamic WHERE
    -- If you pass NULL, then the current column value is set to itself
    PROCEDURE upd
    (
        id_opinion_in          IN opinion_ds.id_opinion%TYPE DEFAULT NULL,
        id_opinion_nin         IN BOOLEAN := TRUE,
        dt_problem_tstz_in     IN opinion_ds.dt_problem_tstz%TYPE DEFAULT NULL,
        dt_problem_tstz_nin    IN BOOLEAN := TRUE,
        id_ds_cmpt_mkt_rel_in  IN opinion_ds.id_ds_cmpt_mkt_rel%TYPE DEFAULT NULL,
        id_ds_cmpt_mkt_rel_nin IN BOOLEAN := TRUE,
        value_in               IN opinion_ds.value%TYPE DEFAULT NULL,
        value_nin              IN BOOLEAN := TRUE,
        value_clob_in          IN opinion_ds.value_clob%TYPE DEFAULT NULL,
        value_clob_nin         IN BOOLEAN := TRUE,
        create_user_in         IN opinion_ds.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN opinion_ds.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN opinion_ds.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN opinion_ds.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN opinion_ds.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN opinion_ds.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        where_in               IN VARCHAR2,
        handle_error_in        IN BOOLEAN := TRUE
    );

    --Update/insert with columns (with rows_out)
    PROCEDURE upd_ins
    (
        id_opinion_ds_in      IN opinion_ds.id_opinion_ds%TYPE,
        id_opinion_in         IN opinion_ds.id_opinion%TYPE DEFAULT NULL,
        dt_problem_tstz_in    IN opinion_ds.dt_problem_tstz%TYPE DEFAULT NULL,
        id_ds_cmpt_mkt_rel_in IN opinion_ds.id_ds_cmpt_mkt_rel%TYPE DEFAULT NULL,
        value_in              IN opinion_ds.value%TYPE DEFAULT NULL,
        value_clob_in         IN opinion_ds.value_clob%TYPE DEFAULT NULL,
        create_user_in        IN opinion_ds.create_user%TYPE DEFAULT NULL,
        create_time_in        IN opinion_ds.create_time%TYPE DEFAULT NULL,
        create_institution_in IN opinion_ds.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN opinion_ds.update_user%TYPE DEFAULT NULL,
        update_time_in        IN opinion_ds.update_time%TYPE DEFAULT NULL,
        update_institution_in IN opinion_ds.update_institution%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              IN OUT table_varchar
    );

    --Update/insert with columns (without rows_out)
    PROCEDURE upd_ins
    (
        id_opinion_ds_in      IN opinion_ds.id_opinion_ds%TYPE,
        id_opinion_in         IN opinion_ds.id_opinion%TYPE DEFAULT NULL,
        dt_problem_tstz_in    IN opinion_ds.dt_problem_tstz%TYPE DEFAULT NULL,
        id_ds_cmpt_mkt_rel_in IN opinion_ds.id_ds_cmpt_mkt_rel%TYPE DEFAULT NULL,
        value_in              IN opinion_ds.value%TYPE DEFAULT NULL,
        value_clob_in         IN opinion_ds.value_clob%TYPE DEFAULT NULL,
        create_user_in        IN opinion_ds.create_user%TYPE DEFAULT NULL,
        create_time_in        IN opinion_ds.create_time%TYPE DEFAULT NULL,
        create_institution_in IN opinion_ds.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN opinion_ds.update_user%TYPE DEFAULT NULL,
        update_time_in        IN opinion_ds.update_time%TYPE DEFAULT NULL,
        update_institution_in IN opinion_ds.update_institution%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE
    );

    --Update record (with rows_out)
    PROCEDURE upd
    (
        rec_in          IN opinion_ds%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    --Update record (without rows_out)
    PROCEDURE upd
    (
        rec_in          IN opinion_ds%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    --Update collection (with rows_out)
    PROCEDURE upd
    (
        col_in            IN opinion_ds_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    --Update collection (without rows_out)
    PROCEDURE upd
    (
        col_in            IN opinion_ds_tc,
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
        id_opinion_ds_in IN opinion_ds.id_opinion_ds%TYPE,
        handle_error_in  IN BOOLEAN := TRUE,
        rows_out         OUT table_varchar
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_opinion_ds_in IN opinion_ds.id_opinion_ds%TYPE,
        handle_error_in  IN BOOLEAN := TRUE
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

    -- Delete all rows for this OPN_DS_MKT_RL_FK foreign key value
    PROCEDURE del_opn_ds_mkt_rl_fk
    (
        id_ds_cmpt_mkt_rel_in IN opinion_ds.id_ds_cmpt_mkt_rel%TYPE,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
    );

    -- Delete all rows for this OPN_DS_OPINION_FK foreign key value
    PROCEDURE del_opn_ds_opinion_fk
    (
        id_opinion_in   IN opinion_ds.id_opinion%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this OPN_DS_MKT_RL_FK foreign key value
    PROCEDURE del_opn_ds_mkt_rl_fk
    (
        id_ds_cmpt_mkt_rel_in IN opinion_ds.id_ds_cmpt_mkt_rel%TYPE,
        handle_error_in       IN BOOLEAN := TRUE
    );

    -- Delete all rows for this OPN_DS_OPINION_FK foreign key value
    PROCEDURE del_opn_ds_opinion_fk
    (
        id_opinion_in   IN opinion_ds.id_opinion%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Initialize a record with default values for columns in the table (prc)
    PROCEDURE initrec(opinion_ds_inout IN OUT opinion_ds%ROWTYPE);

    -- Initialize a record with default values for columns in the table (fnc)
    FUNCTION initrec RETURN opinion_ds%ROWTYPE;

    -- Get data rowid
    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN opinion_ds_tc;

    -- Get data rowid pragma autonomous transaccion
    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN opinion_ds_tc;

END ts_opinion_ds;
/
