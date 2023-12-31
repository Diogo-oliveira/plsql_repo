/*-- Last Change Revision: $Rev: 2029237 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:50:33 +0100 (ter, 02 ago 2022) $*/


CREATE OR REPLACE PACKAGE ts_lens_presc_hist
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: January 22, 2009 20:1:43
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "LENS_PRESC_HIST"
    TYPE lens_presc_hist_tc IS TABLE OF lens_presc_hist%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE lens_presc_hist_ntt IS TABLE OF lens_presc_hist%ROWTYPE;
    TYPE lens_presc_hist_vat IS VARRAY(100) OF lens_presc_hist%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF lens_presc_hist%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF lens_presc_hist%ROWTYPE;
    TYPE vat IS VARRAY(100) OF lens_presc_hist%ROWTYPE;

    -- Column Collection based on column "ID_LENS_PRESC_HIST"
    TYPE id_lens_presc_hist_cc IS TABLE OF lens_presc_hist.id_lens_presc_hist%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_LENS_PRESC"
    TYPE id_lens_presc_cc IS TABLE OF lens_presc_hist.id_lens_presc%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_LENS"
    TYPE id_lens_cc IS TABLE OF lens_presc_hist.id_lens%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_EPISODE"
    TYPE id_episode_cc IS TABLE OF lens_presc_hist.id_episode%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_PATIENT"
    TYPE id_patient_cc IS TABLE OF lens_presc_hist.id_patient%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_PROF_PRESC"
    TYPE id_prof_presc_cc IS TABLE OF lens_presc_hist.id_prof_presc%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_LENS_PRESC_TSTZ"
    TYPE dt_lens_presc_tstz_cc IS TABLE OF lens_presc_hist.dt_lens_presc_tstz%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_PROF_CANCEL"
    TYPE id_prof_cancel_cc IS TABLE OF lens_presc_hist.id_prof_cancel%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_CANCEL_TSTZ"
    TYPE dt_cancel_tstz_cc IS TABLE OF lens_presc_hist.dt_cancel_tstz%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_PROF_PRINT"
    TYPE id_prof_print_cc IS TABLE OF lens_presc_hist.id_prof_print%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_PRINT_TSTZ"
    TYPE dt_print_tstz_cc IS TABLE OF lens_presc_hist.dt_print_tstz%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_STATUS"
    TYPE flg_status_cc IS TABLE OF lens_presc_hist.flg_status%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "NOTES"
    TYPE notes_cc IS TABLE OF lens_presc_hist.notes%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "NOTES_CANCEL"
    TYPE notes_cancel_cc IS TABLE OF lens_presc_hist.notes_cancel%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_CANCEL_REASON"
    TYPE id_cancel_reason_cc IS TABLE OF lens_presc_hist.id_cancel_reason%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_USER"
    TYPE create_user_cc IS TABLE OF lens_presc_hist.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_TIME"
    TYPE create_time_cc IS TABLE OF lens_presc_hist.create_time%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_lens_presc_hist_in IN lens_presc_hist.id_lens_presc_hist%TYPE,
        id_lens_presc_in      IN lens_presc_hist.id_lens_presc%TYPE DEFAULT NULL,
        id_lens_in            IN lens_presc_hist.id_lens%TYPE DEFAULT NULL,
        id_episode_in         IN lens_presc_hist.id_episode%TYPE DEFAULT NULL,
        id_patient_in         IN lens_presc_hist.id_patient%TYPE DEFAULT NULL,
        id_prof_presc_in      IN lens_presc_hist.id_prof_presc%TYPE DEFAULT NULL,
        dt_lens_presc_tstz_in IN lens_presc_hist.dt_lens_presc_tstz%TYPE DEFAULT NULL,
        id_prof_cancel_in     IN lens_presc_hist.id_prof_cancel%TYPE DEFAULT NULL,
        dt_cancel_tstz_in     IN lens_presc_hist.dt_cancel_tstz%TYPE DEFAULT NULL,
        id_prof_print_in      IN lens_presc_hist.id_prof_print%TYPE DEFAULT NULL,
        dt_print_tstz_in      IN lens_presc_hist.dt_print_tstz%TYPE DEFAULT NULL,
        flg_status_in         IN lens_presc_hist.flg_status%TYPE DEFAULT NULL,
        notes_in              IN lens_presc_hist.notes%TYPE DEFAULT NULL,
        notes_cancel_in       IN lens_presc_hist.notes_cancel%TYPE DEFAULT NULL,
        id_cancel_reason_in   IN lens_presc_hist.id_cancel_reason%TYPE DEFAULT NULL,
        create_user_in        IN lens_presc_hist.create_user%TYPE DEFAULT NULL,
        create_time_in        IN lens_presc_hist.create_time%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_lens_presc_hist_in IN lens_presc_hist.id_lens_presc_hist%TYPE,
        id_lens_presc_in      IN lens_presc_hist.id_lens_presc%TYPE DEFAULT NULL,
        id_lens_in            IN lens_presc_hist.id_lens%TYPE DEFAULT NULL,
        id_episode_in         IN lens_presc_hist.id_episode%TYPE DEFAULT NULL,
        id_patient_in         IN lens_presc_hist.id_patient%TYPE DEFAULT NULL,
        id_prof_presc_in      IN lens_presc_hist.id_prof_presc%TYPE DEFAULT NULL,
        dt_lens_presc_tstz_in IN lens_presc_hist.dt_lens_presc_tstz%TYPE DEFAULT NULL,
        id_prof_cancel_in     IN lens_presc_hist.id_prof_cancel%TYPE DEFAULT NULL,
        dt_cancel_tstz_in     IN lens_presc_hist.dt_cancel_tstz%TYPE DEFAULT NULL,
        id_prof_print_in      IN lens_presc_hist.id_prof_print%TYPE DEFAULT NULL,
        dt_print_tstz_in      IN lens_presc_hist.dt_print_tstz%TYPE DEFAULT NULL,
        flg_status_in         IN lens_presc_hist.flg_status%TYPE DEFAULT NULL,
        notes_in              IN lens_presc_hist.notes%TYPE DEFAULT NULL,
        notes_cancel_in       IN lens_presc_hist.notes_cancel%TYPE DEFAULT NULL,
        id_cancel_reason_in   IN lens_presc_hist.id_cancel_reason%TYPE DEFAULT NULL,
        create_user_in        IN lens_presc_hist.create_user%TYPE DEFAULT NULL,
        create_time_in        IN lens_presc_hist.create_time%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    PROCEDURE ins
    (
        rec_in          IN lens_presc_hist%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN lens_presc_hist%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN lens_presc_hist_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN lens_presc_hist_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        id_lens_presc_hist_in  IN lens_presc_hist.id_lens_presc_hist%TYPE,
        id_lens_presc_in       IN lens_presc_hist.id_lens_presc%TYPE DEFAULT NULL,
        id_lens_presc_nin      IN BOOLEAN := TRUE,
        id_lens_in             IN lens_presc_hist.id_lens%TYPE DEFAULT NULL,
        id_lens_nin            IN BOOLEAN := TRUE,
        id_episode_in          IN lens_presc_hist.id_episode%TYPE DEFAULT NULL,
        id_episode_nin         IN BOOLEAN := TRUE,
        id_patient_in          IN lens_presc_hist.id_patient%TYPE DEFAULT NULL,
        id_patient_nin         IN BOOLEAN := TRUE,
        id_prof_presc_in       IN lens_presc_hist.id_prof_presc%TYPE DEFAULT NULL,
        id_prof_presc_nin      IN BOOLEAN := TRUE,
        dt_lens_presc_tstz_in  IN lens_presc_hist.dt_lens_presc_tstz%TYPE DEFAULT NULL,
        dt_lens_presc_tstz_nin IN BOOLEAN := TRUE,
        id_prof_cancel_in      IN lens_presc_hist.id_prof_cancel%TYPE DEFAULT NULL,
        id_prof_cancel_nin     IN BOOLEAN := TRUE,
        dt_cancel_tstz_in      IN lens_presc_hist.dt_cancel_tstz%TYPE DEFAULT NULL,
        dt_cancel_tstz_nin     IN BOOLEAN := TRUE,
        id_prof_print_in       IN lens_presc_hist.id_prof_print%TYPE DEFAULT NULL,
        id_prof_print_nin      IN BOOLEAN := TRUE,
        dt_print_tstz_in       IN lens_presc_hist.dt_print_tstz%TYPE DEFAULT NULL,
        dt_print_tstz_nin      IN BOOLEAN := TRUE,
        flg_status_in          IN lens_presc_hist.flg_status%TYPE DEFAULT NULL,
        flg_status_nin         IN BOOLEAN := TRUE,
        notes_in               IN lens_presc_hist.notes%TYPE DEFAULT NULL,
        notes_nin              IN BOOLEAN := TRUE,
        notes_cancel_in        IN lens_presc_hist.notes_cancel%TYPE DEFAULT NULL,
        notes_cancel_nin       IN BOOLEAN := TRUE,
        id_cancel_reason_in    IN lens_presc_hist.id_cancel_reason%TYPE DEFAULT NULL,
        id_cancel_reason_nin   IN BOOLEAN := TRUE,
        create_user_in         IN lens_presc_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN lens_presc_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_lens_presc_hist_in  IN lens_presc_hist.id_lens_presc_hist%TYPE,
        id_lens_presc_in       IN lens_presc_hist.id_lens_presc%TYPE DEFAULT NULL,
        id_lens_presc_nin      IN BOOLEAN := TRUE,
        id_lens_in             IN lens_presc_hist.id_lens%TYPE DEFAULT NULL,
        id_lens_nin            IN BOOLEAN := TRUE,
        id_episode_in          IN lens_presc_hist.id_episode%TYPE DEFAULT NULL,
        id_episode_nin         IN BOOLEAN := TRUE,
        id_patient_in          IN lens_presc_hist.id_patient%TYPE DEFAULT NULL,
        id_patient_nin         IN BOOLEAN := TRUE,
        id_prof_presc_in       IN lens_presc_hist.id_prof_presc%TYPE DEFAULT NULL,
        id_prof_presc_nin      IN BOOLEAN := TRUE,
        dt_lens_presc_tstz_in  IN lens_presc_hist.dt_lens_presc_tstz%TYPE DEFAULT NULL,
        dt_lens_presc_tstz_nin IN BOOLEAN := TRUE,
        id_prof_cancel_in      IN lens_presc_hist.id_prof_cancel%TYPE DEFAULT NULL,
        id_prof_cancel_nin     IN BOOLEAN := TRUE,
        dt_cancel_tstz_in      IN lens_presc_hist.dt_cancel_tstz%TYPE DEFAULT NULL,
        dt_cancel_tstz_nin     IN BOOLEAN := TRUE,
        id_prof_print_in       IN lens_presc_hist.id_prof_print%TYPE DEFAULT NULL,
        id_prof_print_nin      IN BOOLEAN := TRUE,
        dt_print_tstz_in       IN lens_presc_hist.dt_print_tstz%TYPE DEFAULT NULL,
        dt_print_tstz_nin      IN BOOLEAN := TRUE,
        flg_status_in          IN lens_presc_hist.flg_status%TYPE DEFAULT NULL,
        flg_status_nin         IN BOOLEAN := TRUE,
        notes_in               IN lens_presc_hist.notes%TYPE DEFAULT NULL,
        notes_nin              IN BOOLEAN := TRUE,
        notes_cancel_in        IN lens_presc_hist.notes_cancel%TYPE DEFAULT NULL,
        notes_cancel_nin       IN BOOLEAN := TRUE,
        id_cancel_reason_in    IN lens_presc_hist.id_cancel_reason%TYPE DEFAULT NULL,
        id_cancel_reason_nin   IN BOOLEAN := TRUE,
        create_user_in         IN lens_presc_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN lens_presc_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        id_lens_presc_in       IN lens_presc_hist.id_lens_presc%TYPE DEFAULT NULL,
        id_lens_presc_nin      IN BOOLEAN := TRUE,
        id_lens_in             IN lens_presc_hist.id_lens%TYPE DEFAULT NULL,
        id_lens_nin            IN BOOLEAN := TRUE,
        id_episode_in          IN lens_presc_hist.id_episode%TYPE DEFAULT NULL,
        id_episode_nin         IN BOOLEAN := TRUE,
        id_patient_in          IN lens_presc_hist.id_patient%TYPE DEFAULT NULL,
        id_patient_nin         IN BOOLEAN := TRUE,
        id_prof_presc_in       IN lens_presc_hist.id_prof_presc%TYPE DEFAULT NULL,
        id_prof_presc_nin      IN BOOLEAN := TRUE,
        dt_lens_presc_tstz_in  IN lens_presc_hist.dt_lens_presc_tstz%TYPE DEFAULT NULL,
        dt_lens_presc_tstz_nin IN BOOLEAN := TRUE,
        id_prof_cancel_in      IN lens_presc_hist.id_prof_cancel%TYPE DEFAULT NULL,
        id_prof_cancel_nin     IN BOOLEAN := TRUE,
        dt_cancel_tstz_in      IN lens_presc_hist.dt_cancel_tstz%TYPE DEFAULT NULL,
        dt_cancel_tstz_nin     IN BOOLEAN := TRUE,
        id_prof_print_in       IN lens_presc_hist.id_prof_print%TYPE DEFAULT NULL,
        id_prof_print_nin      IN BOOLEAN := TRUE,
        dt_print_tstz_in       IN lens_presc_hist.dt_print_tstz%TYPE DEFAULT NULL,
        dt_print_tstz_nin      IN BOOLEAN := TRUE,
        flg_status_in          IN lens_presc_hist.flg_status%TYPE DEFAULT NULL,
        flg_status_nin         IN BOOLEAN := TRUE,
        notes_in               IN lens_presc_hist.notes%TYPE DEFAULT NULL,
        notes_nin              IN BOOLEAN := TRUE,
        notes_cancel_in        IN lens_presc_hist.notes_cancel%TYPE DEFAULT NULL,
        notes_cancel_nin       IN BOOLEAN := TRUE,
        id_cancel_reason_in    IN lens_presc_hist.id_cancel_reason%TYPE DEFAULT NULL,
        id_cancel_reason_nin   IN BOOLEAN := TRUE,
        create_user_in         IN lens_presc_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN lens_presc_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        where_in               VARCHAR2 DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_lens_presc_in       IN lens_presc_hist.id_lens_presc%TYPE DEFAULT NULL,
        id_lens_presc_nin      IN BOOLEAN := TRUE,
        id_lens_in             IN lens_presc_hist.id_lens%TYPE DEFAULT NULL,
        id_lens_nin            IN BOOLEAN := TRUE,
        id_episode_in          IN lens_presc_hist.id_episode%TYPE DEFAULT NULL,
        id_episode_nin         IN BOOLEAN := TRUE,
        id_patient_in          IN lens_presc_hist.id_patient%TYPE DEFAULT NULL,
        id_patient_nin         IN BOOLEAN := TRUE,
        id_prof_presc_in       IN lens_presc_hist.id_prof_presc%TYPE DEFAULT NULL,
        id_prof_presc_nin      IN BOOLEAN := TRUE,
        dt_lens_presc_tstz_in  IN lens_presc_hist.dt_lens_presc_tstz%TYPE DEFAULT NULL,
        dt_lens_presc_tstz_nin IN BOOLEAN := TRUE,
        id_prof_cancel_in      IN lens_presc_hist.id_prof_cancel%TYPE DEFAULT NULL,
        id_prof_cancel_nin     IN BOOLEAN := TRUE,
        dt_cancel_tstz_in      IN lens_presc_hist.dt_cancel_tstz%TYPE DEFAULT NULL,
        dt_cancel_tstz_nin     IN BOOLEAN := TRUE,
        id_prof_print_in       IN lens_presc_hist.id_prof_print%TYPE DEFAULT NULL,
        id_prof_print_nin      IN BOOLEAN := TRUE,
        dt_print_tstz_in       IN lens_presc_hist.dt_print_tstz%TYPE DEFAULT NULL,
        dt_print_tstz_nin      IN BOOLEAN := TRUE,
        flg_status_in          IN lens_presc_hist.flg_status%TYPE DEFAULT NULL,
        flg_status_nin         IN BOOLEAN := TRUE,
        notes_in               IN lens_presc_hist.notes%TYPE DEFAULT NULL,
        notes_nin              IN BOOLEAN := TRUE,
        notes_cancel_in        IN lens_presc_hist.notes_cancel%TYPE DEFAULT NULL,
        notes_cancel_nin       IN BOOLEAN := TRUE,
        id_cancel_reason_in    IN lens_presc_hist.id_cancel_reason%TYPE DEFAULT NULL,
        id_cancel_reason_nin   IN BOOLEAN := TRUE,
        create_user_in         IN lens_presc_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN lens_presc_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        where_in               VARCHAR2 DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_lens_presc_hist_in IN lens_presc_hist.id_lens_presc_hist%TYPE,
        id_lens_presc_in      IN lens_presc_hist.id_lens_presc%TYPE DEFAULT NULL,
        id_lens_in            IN lens_presc_hist.id_lens%TYPE DEFAULT NULL,
        id_episode_in         IN lens_presc_hist.id_episode%TYPE DEFAULT NULL,
        id_patient_in         IN lens_presc_hist.id_patient%TYPE DEFAULT NULL,
        id_prof_presc_in      IN lens_presc_hist.id_prof_presc%TYPE DEFAULT NULL,
        dt_lens_presc_tstz_in IN lens_presc_hist.dt_lens_presc_tstz%TYPE DEFAULT NULL,
        id_prof_cancel_in     IN lens_presc_hist.id_prof_cancel%TYPE DEFAULT NULL,
        dt_cancel_tstz_in     IN lens_presc_hist.dt_cancel_tstz%TYPE DEFAULT NULL,
        id_prof_print_in      IN lens_presc_hist.id_prof_print%TYPE DEFAULT NULL,
        dt_print_tstz_in      IN lens_presc_hist.dt_print_tstz%TYPE DEFAULT NULL,
        flg_status_in         IN lens_presc_hist.flg_status%TYPE DEFAULT NULL,
        notes_in              IN lens_presc_hist.notes%TYPE DEFAULT NULL,
        notes_cancel_in       IN lens_presc_hist.notes_cancel%TYPE DEFAULT NULL,
        id_cancel_reason_in   IN lens_presc_hist.id_cancel_reason%TYPE DEFAULT NULL,
        create_user_in        IN lens_presc_hist.create_user%TYPE DEFAULT NULL,
        create_time_in        IN lens_presc_hist.create_time%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_lens_presc_hist_in IN lens_presc_hist.id_lens_presc_hist%TYPE,
        id_lens_presc_in      IN lens_presc_hist.id_lens_presc%TYPE DEFAULT NULL,
        id_lens_in            IN lens_presc_hist.id_lens%TYPE DEFAULT NULL,
        id_episode_in         IN lens_presc_hist.id_episode%TYPE DEFAULT NULL,
        id_patient_in         IN lens_presc_hist.id_patient%TYPE DEFAULT NULL,
        id_prof_presc_in      IN lens_presc_hist.id_prof_presc%TYPE DEFAULT NULL,
        dt_lens_presc_tstz_in IN lens_presc_hist.dt_lens_presc_tstz%TYPE DEFAULT NULL,
        id_prof_cancel_in     IN lens_presc_hist.id_prof_cancel%TYPE DEFAULT NULL,
        dt_cancel_tstz_in     IN lens_presc_hist.dt_cancel_tstz%TYPE DEFAULT NULL,
        id_prof_print_in      IN lens_presc_hist.id_prof_print%TYPE DEFAULT NULL,
        dt_print_tstz_in      IN lens_presc_hist.dt_print_tstz%TYPE DEFAULT NULL,
        flg_status_in         IN lens_presc_hist.flg_status%TYPE DEFAULT NULL,
        notes_in              IN lens_presc_hist.notes%TYPE DEFAULT NULL,
        notes_cancel_in       IN lens_presc_hist.notes_cancel%TYPE DEFAULT NULL,
        id_cancel_reason_in   IN lens_presc_hist.id_cancel_reason%TYPE DEFAULT NULL,
        create_user_in        IN lens_presc_hist.create_user%TYPE DEFAULT NULL,
        create_time_in        IN lens_presc_hist.create_time%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN lens_presc_hist%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN lens_presc_hist%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN lens_presc_hist_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN lens_presc_hist_tc,
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
        id_lens_presc_hist_in IN lens_presc_hist.id_lens_presc_hist%TYPE,
        handle_error_in       IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_lens_presc_hist_in IN lens_presc_hist.id_lens_presc_hist%TYPE,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
    );

    -- Delete all rows for primary key column ID_LENS_PRESC_HIST
    PROCEDURE del_id_lens_presc_hist
    (
        id_lens_presc_hist_in IN lens_presc_hist.id_lens_presc_hist%TYPE,
        handle_error_in       IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_LENS_PRESC_HIST
    PROCEDURE del_id_lens_presc_hist
    (
        id_lens_presc_hist_in IN lens_presc_hist.id_lens_presc_hist%TYPE,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
    );

    -- Delete all rows for this LPH_CRE_FK foreign key value
    PROCEDURE del_lph_cre_fk
    (
        id_cancel_reason_in IN lens_presc_hist.id_cancel_reason%TYPE,
        handle_error_in     IN BOOLEAN := TRUE
    );

    -- Delete all rows for this LPH_CRE_FK foreign key value
    PROCEDURE del_lph_cre_fk
    (
        id_cancel_reason_in IN lens_presc_hist.id_cancel_reason%TYPE,
        handle_error_in     IN BOOLEAN := TRUE,
        rows_out            OUT table_varchar
    );

    -- Delete all rows for this LPH_EPE_FK foreign key value
    PROCEDURE del_lph_epe_fk
    (
        id_episode_in   IN lens_presc_hist.id_episode%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this LPH_EPE_FK foreign key value
    PROCEDURE del_lph_epe_fk
    (
        id_episode_in   IN lens_presc_hist.id_episode%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this LPH_LEN_FK foreign key value
    PROCEDURE del_lph_len_fk
    (
        id_lens_in      IN lens_presc_hist.id_lens%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this LPH_LEN_FK foreign key value
    PROCEDURE del_lph_len_fk
    (
        id_lens_in      IN lens_presc_hist.id_lens%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this LPH_LPC_FK foreign key value
    PROCEDURE del_lph_lpc_fk
    (
        id_lens_presc_in IN lens_presc_hist.id_lens_presc%TYPE,
        handle_error_in  IN BOOLEAN := TRUE
    );

    -- Delete all rows for this LPH_LPC_FK foreign key value
    PROCEDURE del_lph_lpc_fk
    (
        id_lens_presc_in IN lens_presc_hist.id_lens_presc%TYPE,
        handle_error_in  IN BOOLEAN := TRUE,
        rows_out         OUT table_varchar
    );

    -- Delete all rows for this LPH_PAT_FK foreign key value
    PROCEDURE del_lph_pat_fk
    (
        id_patient_in   IN lens_presc_hist.id_patient%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this LPH_PAT_FK foreign key value
    PROCEDURE del_lph_pat_fk
    (
        id_patient_in   IN lens_presc_hist.id_patient%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this LPH_PRL_FK foreign key value
    PROCEDURE del_lph_prl_fk
    (
        id_prof_presc_in IN lens_presc_hist.id_prof_presc%TYPE,
        handle_error_in  IN BOOLEAN := TRUE
    );

    -- Delete all rows for this LPH_PRL_FK foreign key value
    PROCEDURE del_lph_prl_fk
    (
        id_prof_presc_in IN lens_presc_hist.id_prof_presc%TYPE,
        handle_error_in  IN BOOLEAN := TRUE,
        rows_out         OUT table_varchar
    );

    -- Delete all rows for this LPH_PRL_FK2 foreign key value
    PROCEDURE del_lph_prl_fk2
    (
        id_prof_print_in IN lens_presc_hist.id_prof_print%TYPE,
        handle_error_in  IN BOOLEAN := TRUE
    );

    -- Delete all rows for this LPH_PRL_FK2 foreign key value
    PROCEDURE del_lph_prl_fk2
    (
        id_prof_print_in IN lens_presc_hist.id_prof_print%TYPE,
        handle_error_in  IN BOOLEAN := TRUE,
        rows_out         OUT table_varchar
    );

    -- Delete all rows for this LPH_PRL_FK3 foreign key value
    PROCEDURE del_lph_prl_fk3
    (
        id_prof_cancel_in IN lens_presc_hist.id_prof_cancel%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete all rows for this LPH_PRL_FK3 foreign key value
    PROCEDURE del_lph_prl_fk3
    (
        id_prof_cancel_in IN lens_presc_hist.id_prof_cancel%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows for this LPH_PRL_FK4 foreign key value
    PROCEDURE del_lph_prl_fk4
    (
        create_user_in  IN lens_presc_hist.create_user%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this LPH_PRL_FK4 foreign key value
    PROCEDURE del_lph_prl_fk4
    (
        create_user_in  IN lens_presc_hist.create_user%TYPE,
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
    PROCEDURE initrec(lens_presc_hist_inout IN OUT lens_presc_hist%ROWTYPE);

    FUNCTION initrec RETURN lens_presc_hist%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN lens_presc_hist_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN lens_presc_hist_tc;

END ts_lens_presc_hist;
/
