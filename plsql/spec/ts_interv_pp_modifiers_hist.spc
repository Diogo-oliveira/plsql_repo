/*-- Last Change Revision: $Rev: 2029225 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:50:29 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE ts_interv_pp_modifiers_hist
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: January 27, 2016 12:32:43
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "INTERV_PP_MODIFIERS_HIST"
    TYPE interv_pp_modifiers_hist_tc IS TABLE OF interv_pp_modifiers_hist%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE interv_pp_modifiers_hist_ntt IS TABLE OF interv_pp_modifiers_hist%ROWTYPE;
    TYPE interv_pp_modifiers_hist_vat IS VARRAY(100) OF interv_pp_modifiers_hist%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF interv_pp_modifiers_hist%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF interv_pp_modifiers_hist%ROWTYPE;
    TYPE vat IS VARRAY(100) OF interv_pp_modifiers_hist%ROWTYPE;

    -- Column Collection based on column "DT_INTERV_PP_MODIFIERS_HIST"
    TYPE dt_interv_pp_modifiers_hist_cc IS TABLE OF interv_pp_modifiers_hist.dt_interv_pp_modifiers_hist%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_INTERV_PRESC_PLAN_HIST"
    TYPE id_interv_presc_plan_hist_cc IS TABLE OF interv_pp_modifiers_hist.id_interv_presc_plan_hist%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_MODIFIER"
    TYPE id_modifier_cc IS TABLE OF interv_pp_modifiers_hist.id_modifier%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_INST_OWNER"
    TYPE id_inst_owner_cc IS TABLE OF interv_pp_modifiers_hist.id_inst_owner%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_PROF_LAST_UPDATE"
    TYPE id_prof_last_update_cc IS TABLE OF interv_pp_modifiers_hist.id_prof_last_update%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_LAST_UPDATE_TSTZ"
    TYPE dt_last_update_tstz_cc IS TABLE OF interv_pp_modifiers_hist.dt_last_update_tstz%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_USER"
    TYPE create_user_cc IS TABLE OF interv_pp_modifiers_hist.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_TIME"
    TYPE create_time_cc IS TABLE OF interv_pp_modifiers_hist.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_INSTITUTION"
    TYPE create_institution_cc IS TABLE OF interv_pp_modifiers_hist.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_USER"
    TYPE update_user_cc IS TABLE OF interv_pp_modifiers_hist.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_TIME"
    TYPE update_time_cc IS TABLE OF interv_pp_modifiers_hist.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_INSTITUTION"
    TYPE update_institution_cc IS TABLE OF interv_pp_modifiers_hist.update_institution%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        dt_interv_pp_modifiers_hist_in IN interv_pp_modifiers_hist.dt_interv_pp_modifiers_hist%TYPE DEFAULT NULL,
        id_interv_presc_plan_hist_in   IN interv_pp_modifiers_hist.id_interv_presc_plan_hist%TYPE DEFAULT NULL,
        id_modifier_in                 IN interv_pp_modifiers_hist.id_modifier%TYPE DEFAULT NULL,
        id_inst_owner_in               IN interv_pp_modifiers_hist.id_inst_owner%TYPE DEFAULT NULL,
        id_prof_last_update_in         IN interv_pp_modifiers_hist.id_prof_last_update%TYPE DEFAULT NULL,
        dt_last_update_tstz_in         IN interv_pp_modifiers_hist.dt_last_update_tstz%TYPE DEFAULT NULL,
        create_user_in                 IN interv_pp_modifiers_hist.create_user%TYPE DEFAULT NULL,
        create_time_in                 IN interv_pp_modifiers_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in          IN interv_pp_modifiers_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in                 IN interv_pp_modifiers_hist.update_user%TYPE DEFAULT NULL,
        update_time_in                 IN interv_pp_modifiers_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in          IN interv_pp_modifiers_hist.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        dt_interv_pp_modifiers_hist_in IN interv_pp_modifiers_hist.dt_interv_pp_modifiers_hist%TYPE DEFAULT NULL,
        id_interv_presc_plan_hist_in   IN interv_pp_modifiers_hist.id_interv_presc_plan_hist%TYPE DEFAULT NULL,
        id_modifier_in                 IN interv_pp_modifiers_hist.id_modifier%TYPE DEFAULT NULL,
        id_inst_owner_in               IN interv_pp_modifiers_hist.id_inst_owner%TYPE DEFAULT NULL,
        id_prof_last_update_in         IN interv_pp_modifiers_hist.id_prof_last_update%TYPE DEFAULT NULL,
        dt_last_update_tstz_in         IN interv_pp_modifiers_hist.dt_last_update_tstz%TYPE DEFAULT NULL,
        create_user_in                 IN interv_pp_modifiers_hist.create_user%TYPE DEFAULT NULL,
        create_time_in                 IN interv_pp_modifiers_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in          IN interv_pp_modifiers_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in                 IN interv_pp_modifiers_hist.update_user%TYPE DEFAULT NULL,
        update_time_in                 IN interv_pp_modifiers_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in          IN interv_pp_modifiers_hist.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    PROCEDURE ins
    (
        rec_in          IN interv_pp_modifiers_hist%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN interv_pp_modifiers_hist%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN interv_pp_modifiers_hist_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN interv_pp_modifiers_hist_tc,
        handle_error_in IN BOOLEAN := TRUE
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

    -- Delete all rows for this IPRH_IPPH_FK foreign key value
    PROCEDURE del_iprh_ipph_fk
    (
        id_interv_presc_plan_hist_in IN interv_pp_modifiers_hist.id_interv_presc_plan_hist%TYPE,
        handle_error_in              IN BOOLEAN := TRUE
    );

    -- Delete all rows for this IPRH_IPPH_FK foreign key value
    PROCEDURE del_iprh_ipph_fk
    (
        id_interv_presc_plan_hist_in IN interv_pp_modifiers_hist.id_interv_presc_plan_hist%TYPE,
        handle_error_in              IN BOOLEAN := TRUE,
        rows_out                     OUT table_varchar
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
    PROCEDURE initrec(interv_pp_modifiers_hist_inout IN OUT interv_pp_modifiers_hist%ROWTYPE);

    FUNCTION initrec RETURN interv_pp_modifiers_hist%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN interv_pp_modifiers_hist_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN interv_pp_modifiers_hist_tc;

END ts_interv_pp_modifiers_hist;
/
