/*-- Last Change Revision: $Rev: 2029218 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:50:27 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE ts_interv_dep_clin_serv
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: October 16, 2008 18:35:57
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "INTERV_DEP_CLIN_SERV"
    TYPE interv_dep_clin_serv_tc IS TABLE OF interv_dep_clin_serv%ROWTYPE INDEX BY BINARY_INTEGER;

    TYPE interv_dep_clin_serv_ntt IS TABLE OF interv_dep_clin_serv%ROWTYPE;

    TYPE interv_dep_clin_serv_vat IS VARRAY(100) OF interv_dep_clin_serv%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF interv_dep_clin_serv%ROWTYPE INDEX BY BINARY_INTEGER;

    TYPE ntt IS TABLE OF interv_dep_clin_serv%ROWTYPE;

    TYPE vat IS VARRAY(100) OF interv_dep_clin_serv%ROWTYPE;

    -- Column Collection based on column "ID_INTERV_DEP_CLIN_SERV"
    TYPE id_interv_dep_clin_serv_cc IS TABLE OF interv_dep_clin_serv.id_interv_dep_clin_serv%TYPE INDEX BY BINARY_INTEGER;

    -- Column Collection based on column "ID_INTERVENTION"
    TYPE id_intervention_cc IS TABLE OF interv_dep_clin_serv.id_intervention%TYPE INDEX BY BINARY_INTEGER;

    -- Column Collection based on column "ID_DEP_CLIN_SERV"
    TYPE id_dep_clin_serv_cc IS TABLE OF interv_dep_clin_serv.id_dep_clin_serv%TYPE INDEX BY BINARY_INTEGER;

    -- Column Collection based on column "FLG_TYPE"
    TYPE flg_type_cc IS TABLE OF interv_dep_clin_serv.flg_type%TYPE INDEX BY BINARY_INTEGER;

    -- Column Collection based on column "RANK"
    TYPE rank_cc IS TABLE OF interv_dep_clin_serv.rank%TYPE INDEX BY BINARY_INTEGER;

    -- Column Collection based on column "ADW_LAST_UPDATE"
    TYPE adw_last_update_cc IS TABLE OF interv_dep_clin_serv.adw_last_update%TYPE INDEX BY BINARY_INTEGER;

    -- Column Collection based on column "ID_INSTITUTION"
    TYPE id_institution_cc IS TABLE OF interv_dep_clin_serv.id_institution%TYPE INDEX BY BINARY_INTEGER;

    -- Column Collection based on column "ID_PROFESSIONAL"
    TYPE id_professional_cc IS TABLE OF interv_dep_clin_serv.id_professional%TYPE INDEX BY BINARY_INTEGER;

    -- Column Collection based on column "ID_SOFTWARE"
    TYPE id_software_cc IS TABLE OF interv_dep_clin_serv.id_software%TYPE INDEX BY BINARY_INTEGER;

    -- Column Collection based on column "FLG_BANDAID"
    TYPE flg_bandaid_cc IS TABLE OF interv_dep_clin_serv.flg_bandaid%TYPE INDEX BY BINARY_INTEGER;

    -- Column Collection based on column "FLG_CHARGEABLE"
    TYPE flg_chargeable_cc IS TABLE OF interv_dep_clin_serv.flg_chargeable%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_interv_dep_clin_serv_in IN interv_dep_clin_serv.id_interv_dep_clin_serv%TYPE,
        id_intervention_in         IN interv_dep_clin_serv.id_intervention%TYPE DEFAULT NULL,
        id_dep_clin_serv_in        IN interv_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        flg_type_in                IN interv_dep_clin_serv.flg_type%TYPE DEFAULT NULL,
        rank_in                    IN interv_dep_clin_serv.rank%TYPE DEFAULT NULL,
        adw_last_update_in         IN interv_dep_clin_serv.adw_last_update%TYPE DEFAULT SYSDATE,
        id_institution_in          IN interv_dep_clin_serv.id_institution%TYPE DEFAULT NULL,
        id_professional_in         IN interv_dep_clin_serv.id_professional%TYPE DEFAULT NULL,
        id_software_in             IN interv_dep_clin_serv.id_software%TYPE DEFAULT NULL,
        flg_bandaid_in             IN interv_dep_clin_serv.flg_bandaid%TYPE DEFAULT NULL,
        flg_chargeable_in          IN interv_dep_clin_serv.flg_chargeable%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_interv_dep_clin_serv_in IN interv_dep_clin_serv.id_interv_dep_clin_serv%TYPE,
        id_intervention_in         IN interv_dep_clin_serv.id_intervention%TYPE DEFAULT NULL,
        id_dep_clin_serv_in        IN interv_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        flg_type_in                IN interv_dep_clin_serv.flg_type%TYPE DEFAULT NULL,
        rank_in                    IN interv_dep_clin_serv.rank%TYPE DEFAULT NULL,
        adw_last_update_in         IN interv_dep_clin_serv.adw_last_update%TYPE DEFAULT SYSDATE,
        id_institution_in          IN interv_dep_clin_serv.id_institution%TYPE DEFAULT NULL,
        id_professional_in         IN interv_dep_clin_serv.id_professional%TYPE DEFAULT NULL,
        id_software_in             IN interv_dep_clin_serv.id_software%TYPE DEFAULT NULL,
        flg_bandaid_in             IN interv_dep_clin_serv.flg_bandaid%TYPE DEFAULT NULL,
        flg_chargeable_in          IN interv_dep_clin_serv.flg_chargeable%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    -- Specify whether or not a primary key value should be generated.
    PROCEDURE ins
    (
        rec_in          IN interv_dep_clin_serv%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN interv_dep_clin_serv%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN interv_dep_clin_serv_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN interv_dep_clin_serv_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Return next primary key value using the named sequence.
    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN interv_dep_clin_serv.id_interv_dep_clin_serv%TYPE;

    -- Insert one row, generating hidden primary key using a sequence
    PROCEDURE ins
    (
        id_intervention_in  IN interv_dep_clin_serv.id_intervention%TYPE DEFAULT NULL,
        id_dep_clin_serv_in IN interv_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        flg_type_in         IN interv_dep_clin_serv.flg_type%TYPE DEFAULT NULL,
        rank_in             IN interv_dep_clin_serv.rank%TYPE DEFAULT NULL,
        adw_last_update_in  IN interv_dep_clin_serv.adw_last_update%TYPE DEFAULT SYSDATE,
        id_institution_in   IN interv_dep_clin_serv.id_institution%TYPE DEFAULT NULL,
        id_professional_in  IN interv_dep_clin_serv.id_professional%TYPE DEFAULT NULL,
        id_software_in      IN interv_dep_clin_serv.id_software%TYPE DEFAULT NULL,
        flg_bandaid_in      IN interv_dep_clin_serv.flg_bandaid%TYPE DEFAULT NULL,
        flg_chargeable_in   IN interv_dep_clin_serv.flg_chargeable%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_intervention_in  IN interv_dep_clin_serv.id_intervention%TYPE DEFAULT NULL,
        id_dep_clin_serv_in IN interv_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        flg_type_in         IN interv_dep_clin_serv.flg_type%TYPE DEFAULT NULL,
        rank_in             IN interv_dep_clin_serv.rank%TYPE DEFAULT NULL,
        adw_last_update_in  IN interv_dep_clin_serv.adw_last_update%TYPE DEFAULT SYSDATE,
        id_institution_in   IN interv_dep_clin_serv.id_institution%TYPE DEFAULT NULL,
        id_professional_in  IN interv_dep_clin_serv.id_professional%TYPE DEFAULT NULL,
        id_software_in      IN interv_dep_clin_serv.id_software%TYPE DEFAULT NULL,
        flg_bandaid_in      IN interv_dep_clin_serv.flg_bandaid%TYPE DEFAULT NULL,
        flg_chargeable_in   IN interv_dep_clin_serv.flg_chargeable%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row, returning primary key generated by sequence
    PROCEDURE ins
    (
        id_intervention_in          IN interv_dep_clin_serv.id_intervention%TYPE DEFAULT NULL,
        id_dep_clin_serv_in         IN interv_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        flg_type_in                 IN interv_dep_clin_serv.flg_type%TYPE DEFAULT NULL,
        rank_in                     IN interv_dep_clin_serv.rank%TYPE DEFAULT NULL,
        adw_last_update_in          IN interv_dep_clin_serv.adw_last_update%TYPE DEFAULT SYSDATE,
        id_institution_in           IN interv_dep_clin_serv.id_institution%TYPE DEFAULT NULL,
        id_professional_in          IN interv_dep_clin_serv.id_professional%TYPE DEFAULT NULL,
        id_software_in              IN interv_dep_clin_serv.id_software%TYPE DEFAULT NULL,
        flg_bandaid_in              IN interv_dep_clin_serv.flg_bandaid%TYPE DEFAULT NULL,
        flg_chargeable_in           IN interv_dep_clin_serv.flg_chargeable%TYPE DEFAULT NULL,
        id_interv_dep_clin_serv_out IN OUT interv_dep_clin_serv.id_interv_dep_clin_serv%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_intervention_in          IN interv_dep_clin_serv.id_intervention%TYPE DEFAULT NULL,
        id_dep_clin_serv_in         IN interv_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        flg_type_in                 IN interv_dep_clin_serv.flg_type%TYPE DEFAULT NULL,
        rank_in                     IN interv_dep_clin_serv.rank%TYPE DEFAULT NULL,
        adw_last_update_in          IN interv_dep_clin_serv.adw_last_update%TYPE DEFAULT SYSDATE,
        id_institution_in           IN interv_dep_clin_serv.id_institution%TYPE DEFAULT NULL,
        id_professional_in          IN interv_dep_clin_serv.id_professional%TYPE DEFAULT NULL,
        id_software_in              IN interv_dep_clin_serv.id_software%TYPE DEFAULT NULL,
        flg_bandaid_in              IN interv_dep_clin_serv.flg_bandaid%TYPE DEFAULT NULL,
        flg_chargeable_in           IN interv_dep_clin_serv.flg_chargeable%TYPE DEFAULT NULL,
        id_interv_dep_clin_serv_out IN OUT interv_dep_clin_serv.id_interv_dep_clin_serv%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row with function, return generated primary key
    FUNCTION ins
    (
        id_intervention_in  IN interv_dep_clin_serv.id_intervention%TYPE DEFAULT NULL,
        id_dep_clin_serv_in IN interv_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        flg_type_in         IN interv_dep_clin_serv.flg_type%TYPE DEFAULT NULL,
        rank_in             IN interv_dep_clin_serv.rank%TYPE DEFAULT NULL,
        adw_last_update_in  IN interv_dep_clin_serv.adw_last_update%TYPE DEFAULT SYSDATE,
        id_institution_in   IN interv_dep_clin_serv.id_institution%TYPE DEFAULT NULL,
        id_professional_in  IN interv_dep_clin_serv.id_professional%TYPE DEFAULT NULL,
        id_software_in      IN interv_dep_clin_serv.id_software%TYPE DEFAULT NULL,
        flg_bandaid_in      IN interv_dep_clin_serv.flg_bandaid%TYPE DEFAULT NULL,
        flg_chargeable_in   IN interv_dep_clin_serv.flg_chargeable%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    ) RETURN interv_dep_clin_serv.id_interv_dep_clin_serv%TYPE;

    FUNCTION ins
    (
        id_intervention_in  IN interv_dep_clin_serv.id_intervention%TYPE DEFAULT NULL,
        id_dep_clin_serv_in IN interv_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        flg_type_in         IN interv_dep_clin_serv.flg_type%TYPE DEFAULT NULL,
        rank_in             IN interv_dep_clin_serv.rank%TYPE DEFAULT NULL,
        adw_last_update_in  IN interv_dep_clin_serv.adw_last_update%TYPE DEFAULT SYSDATE,
        id_institution_in   IN interv_dep_clin_serv.id_institution%TYPE DEFAULT NULL,
        id_professional_in  IN interv_dep_clin_serv.id_professional%TYPE DEFAULT NULL,
        id_software_in      IN interv_dep_clin_serv.id_software%TYPE DEFAULT NULL,
        flg_bandaid_in      IN interv_dep_clin_serv.flg_bandaid%TYPE DEFAULT NULL,
        flg_chargeable_in   IN interv_dep_clin_serv.flg_chargeable%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    ) RETURN interv_dep_clin_serv.id_interv_dep_clin_serv%TYPE;

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.
    PROCEDURE upd
    (
        id_interv_dep_clin_serv_in IN interv_dep_clin_serv.id_interv_dep_clin_serv%TYPE,
        id_intervention_in         IN interv_dep_clin_serv.id_intervention%TYPE DEFAULT NULL,
        id_intervention_nin        IN BOOLEAN := TRUE,
        id_dep_clin_serv_in        IN interv_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        id_dep_clin_serv_nin       IN BOOLEAN := TRUE,
        flg_type_in                IN interv_dep_clin_serv.flg_type%TYPE DEFAULT NULL,
        flg_type_nin               IN BOOLEAN := TRUE,
        rank_in                    IN interv_dep_clin_serv.rank%TYPE DEFAULT NULL,
        rank_nin                   IN BOOLEAN := TRUE,
        adw_last_update_in         IN interv_dep_clin_serv.adw_last_update%TYPE DEFAULT NULL,
        adw_last_update_nin        IN BOOLEAN := TRUE,
        id_institution_in          IN interv_dep_clin_serv.id_institution%TYPE DEFAULT NULL,
        id_institution_nin         IN BOOLEAN := TRUE,
        id_professional_in         IN interv_dep_clin_serv.id_professional%TYPE DEFAULT NULL,
        id_professional_nin        IN BOOLEAN := TRUE,
        id_software_in             IN interv_dep_clin_serv.id_software%TYPE DEFAULT NULL,
        id_software_nin            IN BOOLEAN := TRUE,
        flg_bandaid_in             IN interv_dep_clin_serv.flg_bandaid%TYPE DEFAULT NULL,
        flg_bandaid_nin            IN BOOLEAN := TRUE,
        flg_chargeable_in          IN interv_dep_clin_serv.flg_chargeable%TYPE DEFAULT NULL,
        flg_chargeable_nin         IN BOOLEAN := TRUE,
        handle_error_in            IN BOOLEAN := TRUE,
        rows_out                   IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_interv_dep_clin_serv_in IN interv_dep_clin_serv.id_interv_dep_clin_serv%TYPE,
        id_intervention_in         IN interv_dep_clin_serv.id_intervention%TYPE DEFAULT NULL,
        id_intervention_nin        IN BOOLEAN := TRUE,
        id_dep_clin_serv_in        IN interv_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        id_dep_clin_serv_nin       IN BOOLEAN := TRUE,
        flg_type_in                IN interv_dep_clin_serv.flg_type%TYPE DEFAULT NULL,
        flg_type_nin               IN BOOLEAN := TRUE,
        rank_in                    IN interv_dep_clin_serv.rank%TYPE DEFAULT NULL,
        rank_nin                   IN BOOLEAN := TRUE,
        adw_last_update_in         IN interv_dep_clin_serv.adw_last_update%TYPE DEFAULT NULL,
        adw_last_update_nin        IN BOOLEAN := TRUE,
        id_institution_in          IN interv_dep_clin_serv.id_institution%TYPE DEFAULT NULL,
        id_institution_nin         IN BOOLEAN := TRUE,
        id_professional_in         IN interv_dep_clin_serv.id_professional%TYPE DEFAULT NULL,
        id_professional_nin        IN BOOLEAN := TRUE,
        id_software_in             IN interv_dep_clin_serv.id_software%TYPE DEFAULT NULL,
        id_software_nin            IN BOOLEAN := TRUE,
        flg_bandaid_in             IN interv_dep_clin_serv.flg_bandaid%TYPE DEFAULT NULL,
        flg_bandaid_nin            IN BOOLEAN := TRUE,
        flg_chargeable_in          IN interv_dep_clin_serv.flg_chargeable%TYPE DEFAULT NULL,
        flg_chargeable_nin         IN BOOLEAN := TRUE,
        handle_error_in            IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        id_intervention_in   IN interv_dep_clin_serv.id_intervention%TYPE DEFAULT NULL,
        id_intervention_nin  IN BOOLEAN := TRUE,
        id_dep_clin_serv_in  IN interv_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        id_dep_clin_serv_nin IN BOOLEAN := TRUE,
        flg_type_in          IN interv_dep_clin_serv.flg_type%TYPE DEFAULT NULL,
        flg_type_nin         IN BOOLEAN := TRUE,
        rank_in              IN interv_dep_clin_serv.rank%TYPE DEFAULT NULL,
        rank_nin             IN BOOLEAN := TRUE,
        adw_last_update_in   IN interv_dep_clin_serv.adw_last_update%TYPE DEFAULT NULL,
        adw_last_update_nin  IN BOOLEAN := TRUE,
        id_institution_in    IN interv_dep_clin_serv.id_institution%TYPE DEFAULT NULL,
        id_institution_nin   IN BOOLEAN := TRUE,
        id_professional_in   IN interv_dep_clin_serv.id_professional%TYPE DEFAULT NULL,
        id_professional_nin  IN BOOLEAN := TRUE,
        id_software_in       IN interv_dep_clin_serv.id_software%TYPE DEFAULT NULL,
        id_software_nin      IN BOOLEAN := TRUE,
        flg_bandaid_in       IN interv_dep_clin_serv.flg_bandaid%TYPE DEFAULT NULL,
        flg_bandaid_nin      IN BOOLEAN := TRUE,
        flg_chargeable_in    IN interv_dep_clin_serv.flg_chargeable%TYPE DEFAULT NULL,
        flg_chargeable_nin   IN BOOLEAN := TRUE,
        where_in             VARCHAR2 DEFAULT NULL,
        handle_error_in      IN BOOLEAN := TRUE,
        rows_out             IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_intervention_in   IN interv_dep_clin_serv.id_intervention%TYPE DEFAULT NULL,
        id_intervention_nin  IN BOOLEAN := TRUE,
        id_dep_clin_serv_in  IN interv_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        id_dep_clin_serv_nin IN BOOLEAN := TRUE,
        flg_type_in          IN interv_dep_clin_serv.flg_type%TYPE DEFAULT NULL,
        flg_type_nin         IN BOOLEAN := TRUE,
        rank_in              IN interv_dep_clin_serv.rank%TYPE DEFAULT NULL,
        rank_nin             IN BOOLEAN := TRUE,
        adw_last_update_in   IN interv_dep_clin_serv.adw_last_update%TYPE DEFAULT NULL,
        adw_last_update_nin  IN BOOLEAN := TRUE,
        id_institution_in    IN interv_dep_clin_serv.id_institution%TYPE DEFAULT NULL,
        id_institution_nin   IN BOOLEAN := TRUE,
        id_professional_in   IN interv_dep_clin_serv.id_professional%TYPE DEFAULT NULL,
        id_professional_nin  IN BOOLEAN := TRUE,
        id_software_in       IN interv_dep_clin_serv.id_software%TYPE DEFAULT NULL,
        id_software_nin      IN BOOLEAN := TRUE,
        flg_bandaid_in       IN interv_dep_clin_serv.flg_bandaid%TYPE DEFAULT NULL,
        flg_bandaid_nin      IN BOOLEAN := TRUE,
        flg_chargeable_in    IN interv_dep_clin_serv.flg_chargeable%TYPE DEFAULT NULL,
        flg_chargeable_nin   IN BOOLEAN := TRUE,
        where_in             VARCHAR2 DEFAULT NULL,
        handle_error_in      IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_interv_dep_clin_serv_in IN interv_dep_clin_serv.id_interv_dep_clin_serv%TYPE,
        id_intervention_in         IN interv_dep_clin_serv.id_intervention%TYPE DEFAULT NULL,
        id_dep_clin_serv_in        IN interv_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        flg_type_in                IN interv_dep_clin_serv.flg_type%TYPE DEFAULT NULL,
        rank_in                    IN interv_dep_clin_serv.rank%TYPE DEFAULT NULL,
        adw_last_update_in         IN interv_dep_clin_serv.adw_last_update%TYPE DEFAULT NULL,
        id_institution_in          IN interv_dep_clin_serv.id_institution%TYPE DEFAULT NULL,
        id_professional_in         IN interv_dep_clin_serv.id_professional%TYPE DEFAULT NULL,
        id_software_in             IN interv_dep_clin_serv.id_software%TYPE DEFAULT NULL,
        flg_bandaid_in             IN interv_dep_clin_serv.flg_bandaid%TYPE DEFAULT NULL,
        flg_chargeable_in          IN interv_dep_clin_serv.flg_chargeable%TYPE DEFAULT NULL,
        handle_error_in            IN BOOLEAN := TRUE,
        rows_out                   OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_interv_dep_clin_serv_in IN interv_dep_clin_serv.id_interv_dep_clin_serv%TYPE,
        id_intervention_in         IN interv_dep_clin_serv.id_intervention%TYPE DEFAULT NULL,
        id_dep_clin_serv_in        IN interv_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        flg_type_in                IN interv_dep_clin_serv.flg_type%TYPE DEFAULT NULL,
        rank_in                    IN interv_dep_clin_serv.rank%TYPE DEFAULT NULL,
        adw_last_update_in         IN interv_dep_clin_serv.adw_last_update%TYPE DEFAULT NULL,
        id_institution_in          IN interv_dep_clin_serv.id_institution%TYPE DEFAULT NULL,
        id_professional_in         IN interv_dep_clin_serv.id_professional%TYPE DEFAULT NULL,
        id_software_in             IN interv_dep_clin_serv.id_software%TYPE DEFAULT NULL,
        flg_bandaid_in             IN interv_dep_clin_serv.flg_bandaid%TYPE DEFAULT NULL,
        flg_chargeable_in          IN interv_dep_clin_serv.flg_chargeable%TYPE DEFAULT NULL,
        handle_error_in            IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN interv_dep_clin_serv%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN interv_dep_clin_serv%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN interv_dep_clin_serv_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN interv_dep_clin_serv_tc,
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
        id_interv_dep_clin_serv_in IN interv_dep_clin_serv.id_interv_dep_clin_serv%TYPE,
        handle_error_in            IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_interv_dep_clin_serv_in IN interv_dep_clin_serv.id_interv_dep_clin_serv%TYPE,
        handle_error_in            IN BOOLEAN := TRUE,
        rows_out                   OUT table_varchar
    );

    -- Delete all rows for primary key column ID_INTERV_DEP_CLIN_SERV
    PROCEDURE del_id_interv_dep_clin_serv
    (
        id_interv_dep_clin_serv_in IN interv_dep_clin_serv.id_interv_dep_clin_serv%TYPE,
        handle_error_in            IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_INTERV_DEP_CLIN_SERV
    PROCEDURE del_id_interv_dep_clin_serv
    (
        id_interv_dep_clin_serv_in IN interv_dep_clin_serv.id_interv_dep_clin_serv%TYPE,
        handle_error_in            IN BOOLEAN := TRUE,
        rows_out                   OUT table_varchar
    );

    -- Delete for unique value of IDCS_INTDCSFTPINSPRFSFT_UIDX
    PROCEDURE del_idcs_intdcsftpinsprfsft_ui
    (
        id_intervention_in  IN interv_dep_clin_serv.id_intervention%TYPE,
        id_dep_clin_serv_in IN interv_dep_clin_serv.id_dep_clin_serv%TYPE,
        flg_type_in         IN interv_dep_clin_serv.flg_type%TYPE,
        id_institution_in   IN interv_dep_clin_serv.id_institution%TYPE,
        id_professional_in  IN interv_dep_clin_serv.id_professional%TYPE,
        id_software_in      IN interv_dep_clin_serv.id_software%TYPE,
        handle_error_in     IN BOOLEAN := TRUE
    );

    -- Delete for unique value of IDCS_INTDCSFTPINSPRFSFT_UIDX
    PROCEDURE del_idcs_intdcsftpinsprfsft_ui
    (
        id_intervention_in  IN interv_dep_clin_serv.id_intervention%TYPE,
        id_dep_clin_serv_in IN interv_dep_clin_serv.id_dep_clin_serv%TYPE,
        flg_type_in         IN interv_dep_clin_serv.flg_type%TYPE,
        id_institution_in   IN interv_dep_clin_serv.id_institution%TYPE,
        id_professional_in  IN interv_dep_clin_serv.id_professional%TYPE,
        id_software_in      IN interv_dep_clin_serv.id_software%TYPE,
        handle_error_in     IN BOOLEAN := TRUE,
        rows_out            OUT table_varchar
    );

    -- Delete all rows for this ICS_DCS_FK foreign key value
    PROCEDURE del_ics_dcs_fk
    (
        id_dep_clin_serv_in IN interv_dep_clin_serv.id_dep_clin_serv%TYPE,
        handle_error_in     IN BOOLEAN := TRUE
    );

    -- Delete all rows for this ICS_DCS_FK foreign key value
    PROCEDURE del_ics_dcs_fk
    (
        id_dep_clin_serv_in IN interv_dep_clin_serv.id_dep_clin_serv%TYPE,
        handle_error_in     IN BOOLEAN := TRUE,
        rows_out            OUT table_varchar
    );

    -- Delete all rows for this ICS_INST_FK foreign key value
    PROCEDURE del_ics_inst_fk
    (
        id_institution_in IN interv_dep_clin_serv.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete all rows for this ICS_INST_FK foreign key value
    PROCEDURE del_ics_inst_fk
    (
        id_institution_in IN interv_dep_clin_serv.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows for this ICS_INT_FK foreign key value
    PROCEDURE del_ics_int_fk
    (
        id_intervention_in IN interv_dep_clin_serv.id_intervention%TYPE,
        handle_error_in    IN BOOLEAN := TRUE
    );

    -- Delete all rows for this ICS_INT_FK foreign key value
    PROCEDURE del_ics_int_fk
    (
        id_intervention_in IN interv_dep_clin_serv.id_intervention%TYPE,
        handle_error_in    IN BOOLEAN := TRUE,
        rows_out           OUT table_varchar
    );

    -- Delete all rows for this ICS_PROF_FK foreign key value
    PROCEDURE del_ics_prof_fk
    (
        id_professional_in IN interv_dep_clin_serv.id_professional%TYPE,
        handle_error_in    IN BOOLEAN := TRUE
    );

    -- Delete all rows for this ICS_PROF_FK foreign key value
    PROCEDURE del_ics_prof_fk
    (
        id_professional_in IN interv_dep_clin_serv.id_professional%TYPE,
        handle_error_in    IN BOOLEAN := TRUE,
        rows_out           OUT table_varchar
    );

    -- Delete all rows for this ICS_S_FK foreign key value
    PROCEDURE del_ics_s_fk
    (
        id_software_in  IN interv_dep_clin_serv.id_software%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this ICS_S_FK foreign key value
    PROCEDURE del_ics_s_fk
    (
        id_software_in  IN interv_dep_clin_serv.id_software%TYPE,
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
    PROCEDURE initrec(interv_dep_clin_serv_inout IN OUT interv_dep_clin_serv%ROWTYPE);

    FUNCTION initrec RETURN interv_dep_clin_serv%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN interv_dep_clin_serv_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN interv_dep_clin_serv_tc;

END ts_interv_dep_clin_serv;
/