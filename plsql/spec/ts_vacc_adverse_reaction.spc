/*-- Last Change Revision: $Rev: 1592933 $*/
/*-- Last Change by: $Author: jorge.silva $*/
/*-- Date of last change: $Date: 2014-05-20 22:54:18 +0100 (ter, 20 mai 2014) $*/
CREATE OR REPLACE PACKAGE ts_vacc_adverse_reaction
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Maio 20, 2014 20:29:34
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "VACC_ADVERSE_REACTION"
    TYPE vacc_adverse_reaction_tc IS TABLE OF vacc_adverse_reaction%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE vacc_adverse_reaction_ntt IS TABLE OF vacc_adverse_reaction%ROWTYPE;
    TYPE vacc_adverse_reaction_vat IS VARRAY(100) OF vacc_adverse_reaction%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF vacc_adverse_reaction%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF vacc_adverse_reaction%ROWTYPE;
    TYPE vat IS VARRAY(100) OF vacc_adverse_reaction%ROWTYPE;

    -- Column Collection based on column "ID_VACC_ADVERSE_REACTION"
    TYPE id_vacc_adverse_reaction_cc IS TABLE OF vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CONCEPT_CODE"
    TYPE concept_code_cc IS TABLE OF vacc_adverse_reaction.concept_code%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CONCEPT_DESCRIPTION"
    TYPE concept_description_cc IS TABLE OF vacc_adverse_reaction.concept_description%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_CONTENT"
    TYPE id_content_cc IS TABLE OF vacc_adverse_reaction.id_content%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_AVAILABLE"
    TYPE flg_available_cc IS TABLE OF vacc_adverse_reaction.flg_available%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_USER"
    TYPE create_user_cc IS TABLE OF vacc_adverse_reaction.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_TIME"
    TYPE create_time_cc IS TABLE OF vacc_adverse_reaction.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_INSTITUTION"
    TYPE create_institution_cc IS TABLE OF vacc_adverse_reaction.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_USER"
    TYPE update_user_cc IS TABLE OF vacc_adverse_reaction.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_TIME"
    TYPE update_time_cc IS TABLE OF vacc_adverse_reaction.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_INSTITUTION"
    TYPE update_institution_cc IS TABLE OF vacc_adverse_reaction.update_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_MARKET"
    TYPE id_market_cc IS TABLE OF vacc_adverse_reaction.id_market%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_vacc_adverse_reaction_in IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE,
        concept_code_in             IN vacc_adverse_reaction.concept_code%TYPE DEFAULT NULL,
        concept_description_in      IN vacc_adverse_reaction.concept_description%TYPE DEFAULT NULL,
        id_content_in               IN vacc_adverse_reaction.id_content%TYPE DEFAULT NULL,
        flg_available_in            IN vacc_adverse_reaction.flg_available%TYPE DEFAULT 'Y',
        create_user_in              IN vacc_adverse_reaction.create_user%TYPE DEFAULT NULL,
        create_time_in              IN vacc_adverse_reaction.create_time%TYPE DEFAULT NULL,
        create_institution_in       IN vacc_adverse_reaction.create_institution%TYPE DEFAULT NULL,
        update_user_in              IN vacc_adverse_reaction.update_user%TYPE DEFAULT NULL,
        update_time_in              IN vacc_adverse_reaction.update_time%TYPE DEFAULT NULL,
        update_institution_in       IN vacc_adverse_reaction.update_institution%TYPE DEFAULT NULL,
        id_market_in                IN vacc_adverse_reaction.id_market%TYPE DEFAULT 0
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_vacc_adverse_reaction_in IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE,
        concept_code_in             IN vacc_adverse_reaction.concept_code%TYPE DEFAULT NULL,
        concept_description_in      IN vacc_adverse_reaction.concept_description%TYPE DEFAULT NULL,
        id_content_in               IN vacc_adverse_reaction.id_content%TYPE DEFAULT NULL,
        flg_available_in            IN vacc_adverse_reaction.flg_available%TYPE DEFAULT 'Y',
        create_user_in              IN vacc_adverse_reaction.create_user%TYPE DEFAULT NULL,
        create_time_in              IN vacc_adverse_reaction.create_time%TYPE DEFAULT NULL,
        create_institution_in       IN vacc_adverse_reaction.create_institution%TYPE DEFAULT NULL,
        update_user_in              IN vacc_adverse_reaction.update_user%TYPE DEFAULT NULL,
        update_time_in              IN vacc_adverse_reaction.update_time%TYPE DEFAULT NULL,
        update_institution_in       IN vacc_adverse_reaction.update_institution%TYPE DEFAULT NULL,
        id_market_in                IN vacc_adverse_reaction.id_market%TYPE DEFAULT 0
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    -- Specify whether or not a primary key value should be generated.
    PROCEDURE ins
    (
        rec_in          IN vacc_adverse_reaction%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN vacc_adverse_reaction%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN vacc_adverse_reaction_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN vacc_adverse_reaction_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Return next primary key value using the named sequence.
    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE;

    -- Insert one row, generating hidden primary key using a sequence
    PROCEDURE ins
    (
        concept_code_in        IN vacc_adverse_reaction.concept_code%TYPE DEFAULT NULL,
        concept_description_in IN vacc_adverse_reaction.concept_description%TYPE DEFAULT NULL,
        id_content_in          IN vacc_adverse_reaction.id_content%TYPE DEFAULT NULL,
        flg_available_in       IN vacc_adverse_reaction.flg_available%TYPE DEFAULT 'Y',
        create_user_in         IN vacc_adverse_reaction.create_user%TYPE DEFAULT NULL,
        create_time_in         IN vacc_adverse_reaction.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN vacc_adverse_reaction.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN vacc_adverse_reaction.update_user%TYPE DEFAULT NULL,
        update_time_in         IN vacc_adverse_reaction.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN vacc_adverse_reaction.update_institution%TYPE DEFAULT NULL,
        id_market_in           IN vacc_adverse_reaction.id_market%TYPE DEFAULT 0
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        concept_code_in        IN vacc_adverse_reaction.concept_code%TYPE DEFAULT NULL,
        concept_description_in IN vacc_adverse_reaction.concept_description%TYPE DEFAULT NULL,
        id_content_in          IN vacc_adverse_reaction.id_content%TYPE DEFAULT NULL,
        flg_available_in       IN vacc_adverse_reaction.flg_available%TYPE DEFAULT 'Y',
        create_user_in         IN vacc_adverse_reaction.create_user%TYPE DEFAULT NULL,
        create_time_in         IN vacc_adverse_reaction.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN vacc_adverse_reaction.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN vacc_adverse_reaction.update_user%TYPE DEFAULT NULL,
        update_time_in         IN vacc_adverse_reaction.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN vacc_adverse_reaction.update_institution%TYPE DEFAULT NULL,
        id_market_in           IN vacc_adverse_reaction.id_market%TYPE DEFAULT 0
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row, returning primary key generated by sequence
    PROCEDURE ins
    (
        concept_code_in              IN vacc_adverse_reaction.concept_code%TYPE DEFAULT NULL,
        concept_description_in       IN vacc_adverse_reaction.concept_description%TYPE DEFAULT NULL,
        id_content_in                IN vacc_adverse_reaction.id_content%TYPE DEFAULT NULL,
        flg_available_in             IN vacc_adverse_reaction.flg_available%TYPE DEFAULT 'Y',
        create_user_in               IN vacc_adverse_reaction.create_user%TYPE DEFAULT NULL,
        create_time_in               IN vacc_adverse_reaction.create_time%TYPE DEFAULT NULL,
        create_institution_in        IN vacc_adverse_reaction.create_institution%TYPE DEFAULT NULL,
        update_user_in               IN vacc_adverse_reaction.update_user%TYPE DEFAULT NULL,
        update_time_in               IN vacc_adverse_reaction.update_time%TYPE DEFAULT NULL,
        update_institution_in        IN vacc_adverse_reaction.update_institution%TYPE DEFAULT NULL,
        id_market_in                 IN vacc_adverse_reaction.id_market%TYPE DEFAULT 0,
        id_vacc_adverse_reaction_out IN OUT vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        concept_code_in              IN vacc_adverse_reaction.concept_code%TYPE DEFAULT NULL,
        concept_description_in       IN vacc_adverse_reaction.concept_description%TYPE DEFAULT NULL,
        id_content_in                IN vacc_adverse_reaction.id_content%TYPE DEFAULT NULL,
        flg_available_in             IN vacc_adverse_reaction.flg_available%TYPE DEFAULT 'Y',
        create_user_in               IN vacc_adverse_reaction.create_user%TYPE DEFAULT NULL,
        create_time_in               IN vacc_adverse_reaction.create_time%TYPE DEFAULT NULL,
        create_institution_in        IN vacc_adverse_reaction.create_institution%TYPE DEFAULT NULL,
        update_user_in               IN vacc_adverse_reaction.update_user%TYPE DEFAULT NULL,
        update_time_in               IN vacc_adverse_reaction.update_time%TYPE DEFAULT NULL,
        update_institution_in        IN vacc_adverse_reaction.update_institution%TYPE DEFAULT NULL,
        id_market_in                 IN vacc_adverse_reaction.id_market%TYPE DEFAULT 0,
        id_vacc_adverse_reaction_out IN OUT vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row with function, return generated primary key
    FUNCTION ins
    (
        concept_code_in        IN vacc_adverse_reaction.concept_code%TYPE DEFAULT NULL,
        concept_description_in IN vacc_adverse_reaction.concept_description%TYPE DEFAULT NULL,
        id_content_in          IN vacc_adverse_reaction.id_content%TYPE DEFAULT NULL,
        flg_available_in       IN vacc_adverse_reaction.flg_available%TYPE DEFAULT 'Y',
        create_user_in         IN vacc_adverse_reaction.create_user%TYPE DEFAULT NULL,
        create_time_in         IN vacc_adverse_reaction.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN vacc_adverse_reaction.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN vacc_adverse_reaction.update_user%TYPE DEFAULT NULL,
        update_time_in         IN vacc_adverse_reaction.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN vacc_adverse_reaction.update_institution%TYPE DEFAULT NULL,
        id_market_in           IN vacc_adverse_reaction.id_market%TYPE DEFAULT 0
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    ) RETURN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE;

    FUNCTION ins
    (
        concept_code_in        IN vacc_adverse_reaction.concept_code%TYPE DEFAULT NULL,
        concept_description_in IN vacc_adverse_reaction.concept_description%TYPE DEFAULT NULL,
        id_content_in          IN vacc_adverse_reaction.id_content%TYPE DEFAULT NULL,
        flg_available_in       IN vacc_adverse_reaction.flg_available%TYPE DEFAULT 'Y',
        create_user_in         IN vacc_adverse_reaction.create_user%TYPE DEFAULT NULL,
        create_time_in         IN vacc_adverse_reaction.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN vacc_adverse_reaction.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN vacc_adverse_reaction.update_user%TYPE DEFAULT NULL,
        update_time_in         IN vacc_adverse_reaction.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN vacc_adverse_reaction.update_institution%TYPE DEFAULT NULL,
        id_market_in           IN vacc_adverse_reaction.id_market%TYPE DEFAULT 0
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    ) RETURN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE;

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        id_vacc_adverse_reaction_in IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE,
        concept_code_in             IN vacc_adverse_reaction.concept_code%TYPE DEFAULT NULL,
        concept_code_nin            IN BOOLEAN := TRUE,
        concept_description_in      IN vacc_adverse_reaction.concept_description%TYPE DEFAULT NULL,
        concept_description_nin     IN BOOLEAN := TRUE,
        id_content_in               IN vacc_adverse_reaction.id_content%TYPE DEFAULT NULL,
        id_content_nin              IN BOOLEAN := TRUE,
        flg_available_in            IN vacc_adverse_reaction.flg_available%TYPE DEFAULT NULL,
        flg_available_nin           IN BOOLEAN := TRUE,
        create_user_in              IN vacc_adverse_reaction.create_user%TYPE DEFAULT NULL,
        create_user_nin             IN BOOLEAN := TRUE,
        create_time_in              IN vacc_adverse_reaction.create_time%TYPE DEFAULT NULL,
        create_time_nin             IN BOOLEAN := TRUE,
        create_institution_in       IN vacc_adverse_reaction.create_institution%TYPE DEFAULT NULL,
        create_institution_nin      IN BOOLEAN := TRUE,
        update_user_in              IN vacc_adverse_reaction.update_user%TYPE DEFAULT NULL,
        update_user_nin             IN BOOLEAN := TRUE,
        update_time_in              IN vacc_adverse_reaction.update_time%TYPE DEFAULT NULL,
        update_time_nin             IN BOOLEAN := TRUE,
        update_institution_in       IN vacc_adverse_reaction.update_institution%TYPE DEFAULT NULL,
        update_institution_nin      IN BOOLEAN := TRUE,
        id_market_in                IN vacc_adverse_reaction.id_market%TYPE DEFAULT NULL,
        id_market_nin               IN BOOLEAN := TRUE,
        handle_error_in             IN BOOLEAN := TRUE,
        rows_out                    IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_vacc_adverse_reaction_in IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE,
        concept_code_in             IN vacc_adverse_reaction.concept_code%TYPE DEFAULT NULL,
        concept_code_nin            IN BOOLEAN := TRUE,
        concept_description_in      IN vacc_adverse_reaction.concept_description%TYPE DEFAULT NULL,
        concept_description_nin     IN BOOLEAN := TRUE,
        id_content_in               IN vacc_adverse_reaction.id_content%TYPE DEFAULT NULL,
        id_content_nin              IN BOOLEAN := TRUE,
        flg_available_in            IN vacc_adverse_reaction.flg_available%TYPE DEFAULT NULL,
        flg_available_nin           IN BOOLEAN := TRUE,
        create_user_in              IN vacc_adverse_reaction.create_user%TYPE DEFAULT NULL,
        create_user_nin             IN BOOLEAN := TRUE,
        create_time_in              IN vacc_adverse_reaction.create_time%TYPE DEFAULT NULL,
        create_time_nin             IN BOOLEAN := TRUE,
        create_institution_in       IN vacc_adverse_reaction.create_institution%TYPE DEFAULT NULL,
        create_institution_nin      IN BOOLEAN := TRUE,
        update_user_in              IN vacc_adverse_reaction.update_user%TYPE DEFAULT NULL,
        update_user_nin             IN BOOLEAN := TRUE,
        update_time_in              IN vacc_adverse_reaction.update_time%TYPE DEFAULT NULL,
        update_time_nin             IN BOOLEAN := TRUE,
        update_institution_in       IN vacc_adverse_reaction.update_institution%TYPE DEFAULT NULL,
        update_institution_nin      IN BOOLEAN := TRUE,
        id_market_in                IN vacc_adverse_reaction.id_market%TYPE DEFAULT NULL,
        id_market_nin               IN BOOLEAN := TRUE,
        handle_error_in             IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        concept_code_in         IN vacc_adverse_reaction.concept_code%TYPE DEFAULT NULL,
        concept_code_nin        IN BOOLEAN := TRUE,
        concept_description_in  IN vacc_adverse_reaction.concept_description%TYPE DEFAULT NULL,
        concept_description_nin IN BOOLEAN := TRUE,
        id_content_in           IN vacc_adverse_reaction.id_content%TYPE DEFAULT NULL,
        id_content_nin          IN BOOLEAN := TRUE,
        flg_available_in        IN vacc_adverse_reaction.flg_available%TYPE DEFAULT NULL,
        flg_available_nin       IN BOOLEAN := TRUE,
        create_user_in          IN vacc_adverse_reaction.create_user%TYPE DEFAULT NULL,
        create_user_nin         IN BOOLEAN := TRUE,
        create_time_in          IN vacc_adverse_reaction.create_time%TYPE DEFAULT NULL,
        create_time_nin         IN BOOLEAN := TRUE,
        create_institution_in   IN vacc_adverse_reaction.create_institution%TYPE DEFAULT NULL,
        create_institution_nin  IN BOOLEAN := TRUE,
        update_user_in          IN vacc_adverse_reaction.update_user%TYPE DEFAULT NULL,
        update_user_nin         IN BOOLEAN := TRUE,
        update_time_in          IN vacc_adverse_reaction.update_time%TYPE DEFAULT NULL,
        update_time_nin         IN BOOLEAN := TRUE,
        update_institution_in   IN vacc_adverse_reaction.update_institution%TYPE DEFAULT NULL,
        update_institution_nin  IN BOOLEAN := TRUE,
        id_market_in            IN vacc_adverse_reaction.id_market%TYPE DEFAULT NULL,
        id_market_nin           IN BOOLEAN := TRUE,
        where_in                VARCHAR2,
        handle_error_in         IN BOOLEAN := TRUE,
        rows_out                IN OUT table_varchar
    );

    PROCEDURE upd
    (
        concept_code_in         IN vacc_adverse_reaction.concept_code%TYPE DEFAULT NULL,
        concept_code_nin        IN BOOLEAN := TRUE,
        concept_description_in  IN vacc_adverse_reaction.concept_description%TYPE DEFAULT NULL,
        concept_description_nin IN BOOLEAN := TRUE,
        id_content_in           IN vacc_adverse_reaction.id_content%TYPE DEFAULT NULL,
        id_content_nin          IN BOOLEAN := TRUE,
        flg_available_in        IN vacc_adverse_reaction.flg_available%TYPE DEFAULT NULL,
        flg_available_nin       IN BOOLEAN := TRUE,
        create_user_in          IN vacc_adverse_reaction.create_user%TYPE DEFAULT NULL,
        create_user_nin         IN BOOLEAN := TRUE,
        create_time_in          IN vacc_adverse_reaction.create_time%TYPE DEFAULT NULL,
        create_time_nin         IN BOOLEAN := TRUE,
        create_institution_in   IN vacc_adverse_reaction.create_institution%TYPE DEFAULT NULL,
        create_institution_nin  IN BOOLEAN := TRUE,
        update_user_in          IN vacc_adverse_reaction.update_user%TYPE DEFAULT NULL,
        update_user_nin         IN BOOLEAN := TRUE,
        update_time_in          IN vacc_adverse_reaction.update_time%TYPE DEFAULT NULL,
        update_time_nin         IN BOOLEAN := TRUE,
        update_institution_in   IN vacc_adverse_reaction.update_institution%TYPE DEFAULT NULL,
        update_institution_nin  IN BOOLEAN := TRUE,
        id_market_in            IN vacc_adverse_reaction.id_market%TYPE DEFAULT NULL,
        id_market_nin           IN BOOLEAN := TRUE,
        where_in                VARCHAR2,
        handle_error_in         IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_vacc_adverse_reaction_in IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE,
        concept_code_in             IN vacc_adverse_reaction.concept_code%TYPE DEFAULT NULL,
        concept_description_in      IN vacc_adverse_reaction.concept_description%TYPE DEFAULT NULL,
        id_content_in               IN vacc_adverse_reaction.id_content%TYPE DEFAULT NULL,
        flg_available_in            IN vacc_adverse_reaction.flg_available%TYPE DEFAULT NULL,
        create_user_in              IN vacc_adverse_reaction.create_user%TYPE DEFAULT NULL,
        create_time_in              IN vacc_adverse_reaction.create_time%TYPE DEFAULT NULL,
        create_institution_in       IN vacc_adverse_reaction.create_institution%TYPE DEFAULT NULL,
        update_user_in              IN vacc_adverse_reaction.update_user%TYPE DEFAULT NULL,
        update_time_in              IN vacc_adverse_reaction.update_time%TYPE DEFAULT NULL,
        update_institution_in       IN vacc_adverse_reaction.update_institution%TYPE DEFAULT NULL,
        id_market_in                IN vacc_adverse_reaction.id_market%TYPE DEFAULT NULL,
        handle_error_in             IN BOOLEAN := TRUE,
        rows_out                    OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_vacc_adverse_reaction_in IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE,
        concept_code_in             IN vacc_adverse_reaction.concept_code%TYPE DEFAULT NULL,
        concept_description_in      IN vacc_adverse_reaction.concept_description%TYPE DEFAULT NULL,
        id_content_in               IN vacc_adverse_reaction.id_content%TYPE DEFAULT NULL,
        flg_available_in            IN vacc_adverse_reaction.flg_available%TYPE DEFAULT NULL,
        create_user_in              IN vacc_adverse_reaction.create_user%TYPE DEFAULT NULL,
        create_time_in              IN vacc_adverse_reaction.create_time%TYPE DEFAULT NULL,
        create_institution_in       IN vacc_adverse_reaction.create_institution%TYPE DEFAULT NULL,
        update_user_in              IN vacc_adverse_reaction.update_user%TYPE DEFAULT NULL,
        update_time_in              IN vacc_adverse_reaction.update_time%TYPE DEFAULT NULL,
        update_institution_in       IN vacc_adverse_reaction.update_institution%TYPE DEFAULT NULL,
        id_market_in                IN vacc_adverse_reaction.id_market%TYPE DEFAULT NULL,
        handle_error_in             IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN vacc_adverse_reaction%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN vacc_adverse_reaction%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN vacc_adverse_reaction_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN vacc_adverse_reaction_tc,
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
        id_vacc_adverse_reaction_in IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE,
        handle_error_in             IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_vacc_adverse_reaction_in IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE,
        handle_error_in             IN BOOLEAN := TRUE,
        rows_out                    OUT table_varchar
    );

    -- Delete all rows for primary key column ID_VACC_ADVERSE_REACTION
    PROCEDURE del_id_vacc_adverse_reaction
    (
        id_vacc_adverse_reaction_in IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE,
        handle_error_in             IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_VACC_ADVERSE_REACTION
    PROCEDURE del_id_vacc_adverse_reaction
    (
        id_vacc_adverse_reaction_in IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE,
        handle_error_in             IN BOOLEAN := TRUE,
        rows_out                    OUT table_varchar
    );

    -- Delete all rows for this VAR_MARKET_FK foreign key value
    PROCEDURE del_var_market_fk
    (
        id_market_in    IN vacc_adverse_reaction.id_market%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this VAR_MARKET_FK foreign key value
    PROCEDURE del_var_market_fk
    (
        id_market_in    IN vacc_adverse_reaction.id_market%TYPE,
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
    PROCEDURE initrec(vacc_adverse_reaction_inout IN OUT vacc_adverse_reaction%ROWTYPE);

    FUNCTION initrec RETURN vacc_adverse_reaction%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN vacc_adverse_reaction_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN vacc_adverse_reaction_tc;

END ts_vacc_adverse_reaction;
/
