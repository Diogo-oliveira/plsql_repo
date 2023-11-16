/*-- Last Change Revision: $Rev: 2029408 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:51:30 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE ts_vital_signs_ea
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Agosto 18, 2009 11:25:46
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "VITAL_SIGNS_EA"
    TYPE vital_signs_ea_tc IS TABLE OF vital_signs_ea%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE vital_signs_ea_ntt IS TABLE OF vital_signs_ea%ROWTYPE;
    TYPE vital_signs_ea_vat IS VARRAY(100) OF vital_signs_ea%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF vital_signs_ea%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF vital_signs_ea%ROWTYPE;
    TYPE vat IS VARRAY(100) OF vital_signs_ea%ROWTYPE;

    -- Column Collection based on column "ID_VITAL_SIGN"
    TYPE id_vital_sign_cc IS TABLE OF vital_signs_ea.id_vital_sign%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_VITAL_SIGN_READ"
    TYPE id_vital_sign_read_cc IS TABLE OF vital_signs_ea.id_vital_sign_read%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_VITAL_SIGN_DESC"
    TYPE id_vital_sign_desc_cc IS TABLE OF vital_signs_ea.id_vital_sign_desc%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "VALUE"
    TYPE value_cc IS TABLE OF vital_signs_ea.value%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_UNIT_MEASURE"
    TYPE id_unit_measure_cc IS TABLE OF vital_signs_ea.id_unit_measure%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_VITAL_SIGN_READ"
    TYPE dt_vital_sign_read_cc IS TABLE OF vital_signs_ea.dt_vital_sign_read%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_PAIN"
    TYPE flg_pain_cc IS TABLE OF vital_signs_ea.flg_pain%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_PROF_READ"
    TYPE id_prof_read_cc IS TABLE OF vital_signs_ea.id_prof_read%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_PROF_CANCEL"
    TYPE id_prof_cancel_cc IS TABLE OF vital_signs_ea.id_prof_cancel%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "NOTES_CANCEL"
    TYPE notes_cancel_cc IS TABLE OF vital_signs_ea.notes_cancel%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_STATE"
    TYPE flg_state_cc IS TABLE OF vital_signs_ea.flg_state%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_CANCEL"
    TYPE dt_cancel_cc IS TABLE OF vital_signs_ea.dt_cancel%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_AVAILABLE"
    TYPE flg_available_cc IS TABLE OF vital_signs_ea.flg_available%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_INSTITUTION_READ"
    TYPE id_institution_read_cc IS TABLE OF vital_signs_ea.id_institution_read%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_STATUS_EPIS"
    TYPE flg_status_epis_cc IS TABLE OF vital_signs_ea.flg_status_epis%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_VISIT"
    TYPE id_visit_cc IS TABLE OF vital_signs_ea.id_visit%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_EPISODE"
    TYPE id_episode_cc IS TABLE OF vital_signs_ea.id_episode%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_PATIENT"
    TYPE id_patient_cc IS TABLE OF vital_signs_ea.id_patient%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "RELATION_DOMAIN"
    TYPE relation_domain_cc IS TABLE OF vital_signs_ea.relation_domain%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_EPIS_TRIAGE"
    TYPE id_epis_triage_cc IS TABLE OF vital_signs_ea.id_epis_triage%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_DG_LAST_UPDATE"
    TYPE dt_dg_last_update_cc IS TABLE OF vital_signs_ea.dt_dg_last_update%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_USER"
    TYPE create_user_cc IS TABLE OF vital_signs_ea.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_TIME"
    TYPE create_time_cc IS TABLE OF vital_signs_ea.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_INSTITUTION"
    TYPE create_institution_cc IS TABLE OF vital_signs_ea.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_USER"
    TYPE update_user_cc IS TABLE OF vital_signs_ea.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_TIME"
    TYPE update_time_cc IS TABLE OF vital_signs_ea.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_INSTITUTION"
    TYPE update_institution_cc IS TABLE OF vital_signs_ea.update_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_VS_SCALES_ELEMENT"
    TYPE id_vs_scales_element_cc IS TABLE OF vital_signs_ea.id_vs_scales_element%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_vital_sign_read_in   IN vital_signs_ea.id_vital_sign_read%TYPE,
        id_vital_sign_in        IN vital_signs_ea.id_vital_sign%TYPE DEFAULT NULL,
        id_vital_sign_desc_in   IN vital_signs_ea.id_vital_sign_desc%TYPE DEFAULT NULL,
        value_in                IN vital_signs_ea.value%TYPE DEFAULT NULL,
        id_unit_measure_in      IN vital_signs_ea.id_unit_measure%TYPE DEFAULT NULL,
        dt_vital_sign_read_in   IN vital_signs_ea.dt_vital_sign_read%TYPE DEFAULT NULL,
        flg_pain_in             IN vital_signs_ea.flg_pain%TYPE DEFAULT NULL,
        id_prof_read_in         IN vital_signs_ea.id_prof_read%TYPE DEFAULT NULL,
        id_prof_cancel_in       IN vital_signs_ea.id_prof_cancel%TYPE DEFAULT NULL,
        notes_cancel_in         IN vital_signs_ea.notes_cancel%TYPE DEFAULT NULL,
        flg_state_in            IN vital_signs_ea.flg_state%TYPE DEFAULT NULL,
        dt_cancel_in            IN vital_signs_ea.dt_cancel%TYPE DEFAULT NULL,
        flg_available_in        IN vital_signs_ea.flg_available%TYPE DEFAULT NULL,
        id_institution_read_in  IN vital_signs_ea.id_institution_read%TYPE DEFAULT NULL,
        flg_status_epis_in      IN vital_signs_ea.flg_status_epis%TYPE DEFAULT NULL,
        id_visit_in             IN vital_signs_ea.id_visit%TYPE DEFAULT NULL,
        id_episode_in           IN vital_signs_ea.id_episode%TYPE DEFAULT NULL,
        id_patient_in           IN vital_signs_ea.id_patient%TYPE DEFAULT NULL,
        relation_domain_in      IN vital_signs_ea.relation_domain%TYPE DEFAULT NULL,
        id_epis_triage_in       IN vital_signs_ea.id_epis_triage%TYPE DEFAULT NULL,
        dt_dg_last_update_in    IN vital_signs_ea.dt_dg_last_update%TYPE DEFAULT current_timestamp,
        create_user_in          IN vital_signs_ea.create_user%TYPE DEFAULT NULL,
        create_time_in          IN vital_signs_ea.create_time%TYPE DEFAULT NULL,
        create_institution_in   IN vital_signs_ea.create_institution%TYPE DEFAULT NULL,
        update_user_in          IN vital_signs_ea.update_user%TYPE DEFAULT NULL,
        update_time_in          IN vital_signs_ea.update_time%TYPE DEFAULT NULL,
        update_institution_in   IN vital_signs_ea.update_institution%TYPE DEFAULT NULL,
        id_vs_scales_element_in IN vital_signs_ea.id_vs_scales_element%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_vital_sign_read_in   IN vital_signs_ea.id_vital_sign_read%TYPE,
        id_vital_sign_in        IN vital_signs_ea.id_vital_sign%TYPE DEFAULT NULL,
        id_vital_sign_desc_in   IN vital_signs_ea.id_vital_sign_desc%TYPE DEFAULT NULL,
        value_in                IN vital_signs_ea.value%TYPE DEFAULT NULL,
        id_unit_measure_in      IN vital_signs_ea.id_unit_measure%TYPE DEFAULT NULL,
        dt_vital_sign_read_in   IN vital_signs_ea.dt_vital_sign_read%TYPE DEFAULT NULL,
        flg_pain_in             IN vital_signs_ea.flg_pain%TYPE DEFAULT NULL,
        id_prof_read_in         IN vital_signs_ea.id_prof_read%TYPE DEFAULT NULL,
        id_prof_cancel_in       IN vital_signs_ea.id_prof_cancel%TYPE DEFAULT NULL,
        notes_cancel_in         IN vital_signs_ea.notes_cancel%TYPE DEFAULT NULL,
        flg_state_in            IN vital_signs_ea.flg_state%TYPE DEFAULT NULL,
        dt_cancel_in            IN vital_signs_ea.dt_cancel%TYPE DEFAULT NULL,
        flg_available_in        IN vital_signs_ea.flg_available%TYPE DEFAULT NULL,
        id_institution_read_in  IN vital_signs_ea.id_institution_read%TYPE DEFAULT NULL,
        flg_status_epis_in      IN vital_signs_ea.flg_status_epis%TYPE DEFAULT NULL,
        id_visit_in             IN vital_signs_ea.id_visit%TYPE DEFAULT NULL,
        id_episode_in           IN vital_signs_ea.id_episode%TYPE DEFAULT NULL,
        id_patient_in           IN vital_signs_ea.id_patient%TYPE DEFAULT NULL,
        relation_domain_in      IN vital_signs_ea.relation_domain%TYPE DEFAULT NULL,
        id_epis_triage_in       IN vital_signs_ea.id_epis_triage%TYPE DEFAULT NULL,
        dt_dg_last_update_in    IN vital_signs_ea.dt_dg_last_update%TYPE DEFAULT current_timestamp,
        create_user_in          IN vital_signs_ea.create_user%TYPE DEFAULT NULL,
        create_time_in          IN vital_signs_ea.create_time%TYPE DEFAULT NULL,
        create_institution_in   IN vital_signs_ea.create_institution%TYPE DEFAULT NULL,
        update_user_in          IN vital_signs_ea.update_user%TYPE DEFAULT NULL,
        update_time_in          IN vital_signs_ea.update_time%TYPE DEFAULT NULL,
        update_institution_in   IN vital_signs_ea.update_institution%TYPE DEFAULT NULL,
        id_vs_scales_element_in IN vital_signs_ea.id_vs_scales_element%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    PROCEDURE ins
    (
        rec_in          IN vital_signs_ea%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN vital_signs_ea%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN vital_signs_ea_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN vital_signs_ea_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        id_vital_sign_read_in    IN vital_signs_ea.id_vital_sign_read%TYPE,
        id_vital_sign_in         IN vital_signs_ea.id_vital_sign%TYPE DEFAULT NULL,
        id_vital_sign_nin        IN BOOLEAN := TRUE,
        id_vital_sign_desc_in    IN vital_signs_ea.id_vital_sign_desc%TYPE DEFAULT NULL,
        id_vital_sign_desc_nin   IN BOOLEAN := TRUE,
        value_in                 IN vital_signs_ea.value%TYPE DEFAULT NULL,
        value_nin                IN BOOLEAN := TRUE,
        id_unit_measure_in       IN vital_signs_ea.id_unit_measure%TYPE DEFAULT NULL,
        id_unit_measure_nin      IN BOOLEAN := TRUE,
        dt_vital_sign_read_in    IN vital_signs_ea.dt_vital_sign_read%TYPE DEFAULT NULL,
        dt_vital_sign_read_nin   IN BOOLEAN := TRUE,
        flg_pain_in              IN vital_signs_ea.flg_pain%TYPE DEFAULT NULL,
        flg_pain_nin             IN BOOLEAN := TRUE,
        id_prof_read_in          IN vital_signs_ea.id_prof_read%TYPE DEFAULT NULL,
        id_prof_read_nin         IN BOOLEAN := TRUE,
        id_prof_cancel_in        IN vital_signs_ea.id_prof_cancel%TYPE DEFAULT NULL,
        id_prof_cancel_nin       IN BOOLEAN := TRUE,
        notes_cancel_in          IN vital_signs_ea.notes_cancel%TYPE DEFAULT NULL,
        notes_cancel_nin         IN BOOLEAN := TRUE,
        flg_state_in             IN vital_signs_ea.flg_state%TYPE DEFAULT NULL,
        flg_state_nin            IN BOOLEAN := TRUE,
        dt_cancel_in             IN vital_signs_ea.dt_cancel%TYPE DEFAULT NULL,
        dt_cancel_nin            IN BOOLEAN := TRUE,
        flg_available_in         IN vital_signs_ea.flg_available%TYPE DEFAULT NULL,
        flg_available_nin        IN BOOLEAN := TRUE,
        id_institution_read_in   IN vital_signs_ea.id_institution_read%TYPE DEFAULT NULL,
        id_institution_read_nin  IN BOOLEAN := TRUE,
        flg_status_epis_in       IN vital_signs_ea.flg_status_epis%TYPE DEFAULT NULL,
        flg_status_epis_nin      IN BOOLEAN := TRUE,
        id_visit_in              IN vital_signs_ea.id_visit%TYPE DEFAULT NULL,
        id_visit_nin             IN BOOLEAN := TRUE,
        id_episode_in            IN vital_signs_ea.id_episode%TYPE DEFAULT NULL,
        id_episode_nin           IN BOOLEAN := TRUE,
        id_patient_in            IN vital_signs_ea.id_patient%TYPE DEFAULT NULL,
        id_patient_nin           IN BOOLEAN := TRUE,
        relation_domain_in       IN vital_signs_ea.relation_domain%TYPE DEFAULT NULL,
        relation_domain_nin      IN BOOLEAN := TRUE,
        id_epis_triage_in        IN vital_signs_ea.id_epis_triage%TYPE DEFAULT NULL,
        id_epis_triage_nin       IN BOOLEAN := TRUE,
        dt_dg_last_update_in     IN vital_signs_ea.dt_dg_last_update%TYPE DEFAULT NULL,
        dt_dg_last_update_nin    IN BOOLEAN := TRUE,
        create_user_in           IN vital_signs_ea.create_user%TYPE DEFAULT NULL,
        create_user_nin          IN BOOLEAN := TRUE,
        create_time_in           IN vital_signs_ea.create_time%TYPE DEFAULT NULL,
        create_time_nin          IN BOOLEAN := TRUE,
        create_institution_in    IN vital_signs_ea.create_institution%TYPE DEFAULT NULL,
        create_institution_nin   IN BOOLEAN := TRUE,
        update_user_in           IN vital_signs_ea.update_user%TYPE DEFAULT NULL,
        update_user_nin          IN BOOLEAN := TRUE,
        update_time_in           IN vital_signs_ea.update_time%TYPE DEFAULT NULL,
        update_time_nin          IN BOOLEAN := TRUE,
        update_institution_in    IN vital_signs_ea.update_institution%TYPE DEFAULT NULL,
        update_institution_nin   IN BOOLEAN := TRUE,
        id_vs_scales_element_in  IN vital_signs_ea.id_vs_scales_element%TYPE DEFAULT NULL,
        id_vs_scales_element_nin IN BOOLEAN := TRUE,
        handle_error_in          IN BOOLEAN := TRUE,
        rows_out                 IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_vital_sign_read_in    IN vital_signs_ea.id_vital_sign_read%TYPE,
        id_vital_sign_in         IN vital_signs_ea.id_vital_sign%TYPE DEFAULT NULL,
        id_vital_sign_nin        IN BOOLEAN := TRUE,
        id_vital_sign_desc_in    IN vital_signs_ea.id_vital_sign_desc%TYPE DEFAULT NULL,
        id_vital_sign_desc_nin   IN BOOLEAN := TRUE,
        value_in                 IN vital_signs_ea.value%TYPE DEFAULT NULL,
        value_nin                IN BOOLEAN := TRUE,
        id_unit_measure_in       IN vital_signs_ea.id_unit_measure%TYPE DEFAULT NULL,
        id_unit_measure_nin      IN BOOLEAN := TRUE,
        dt_vital_sign_read_in    IN vital_signs_ea.dt_vital_sign_read%TYPE DEFAULT NULL,
        dt_vital_sign_read_nin   IN BOOLEAN := TRUE,
        flg_pain_in              IN vital_signs_ea.flg_pain%TYPE DEFAULT NULL,
        flg_pain_nin             IN BOOLEAN := TRUE,
        id_prof_read_in          IN vital_signs_ea.id_prof_read%TYPE DEFAULT NULL,
        id_prof_read_nin         IN BOOLEAN := TRUE,
        id_prof_cancel_in        IN vital_signs_ea.id_prof_cancel%TYPE DEFAULT NULL,
        id_prof_cancel_nin       IN BOOLEAN := TRUE,
        notes_cancel_in          IN vital_signs_ea.notes_cancel%TYPE DEFAULT NULL,
        notes_cancel_nin         IN BOOLEAN := TRUE,
        flg_state_in             IN vital_signs_ea.flg_state%TYPE DEFAULT NULL,
        flg_state_nin            IN BOOLEAN := TRUE,
        dt_cancel_in             IN vital_signs_ea.dt_cancel%TYPE DEFAULT NULL,
        dt_cancel_nin            IN BOOLEAN := TRUE,
        flg_available_in         IN vital_signs_ea.flg_available%TYPE DEFAULT NULL,
        flg_available_nin        IN BOOLEAN := TRUE,
        id_institution_read_in   IN vital_signs_ea.id_institution_read%TYPE DEFAULT NULL,
        id_institution_read_nin  IN BOOLEAN := TRUE,
        flg_status_epis_in       IN vital_signs_ea.flg_status_epis%TYPE DEFAULT NULL,
        flg_status_epis_nin      IN BOOLEAN := TRUE,
        id_visit_in              IN vital_signs_ea.id_visit%TYPE DEFAULT NULL,
        id_visit_nin             IN BOOLEAN := TRUE,
        id_episode_in            IN vital_signs_ea.id_episode%TYPE DEFAULT NULL,
        id_episode_nin           IN BOOLEAN := TRUE,
        id_patient_in            IN vital_signs_ea.id_patient%TYPE DEFAULT NULL,
        id_patient_nin           IN BOOLEAN := TRUE,
        relation_domain_in       IN vital_signs_ea.relation_domain%TYPE DEFAULT NULL,
        relation_domain_nin      IN BOOLEAN := TRUE,
        id_epis_triage_in        IN vital_signs_ea.id_epis_triage%TYPE DEFAULT NULL,
        id_epis_triage_nin       IN BOOLEAN := TRUE,
        dt_dg_last_update_in     IN vital_signs_ea.dt_dg_last_update%TYPE DEFAULT NULL,
        dt_dg_last_update_nin    IN BOOLEAN := TRUE,
        create_user_in           IN vital_signs_ea.create_user%TYPE DEFAULT NULL,
        create_user_nin          IN BOOLEAN := TRUE,
        create_time_in           IN vital_signs_ea.create_time%TYPE DEFAULT NULL,
        create_time_nin          IN BOOLEAN := TRUE,
        create_institution_in    IN vital_signs_ea.create_institution%TYPE DEFAULT NULL,
        create_institution_nin   IN BOOLEAN := TRUE,
        update_user_in           IN vital_signs_ea.update_user%TYPE DEFAULT NULL,
        update_user_nin          IN BOOLEAN := TRUE,
        update_time_in           IN vital_signs_ea.update_time%TYPE DEFAULT NULL,
        update_time_nin          IN BOOLEAN := TRUE,
        update_institution_in    IN vital_signs_ea.update_institution%TYPE DEFAULT NULL,
        update_institution_nin   IN BOOLEAN := TRUE,
        id_vs_scales_element_in  IN vital_signs_ea.id_vs_scales_element%TYPE DEFAULT NULL,
        id_vs_scales_element_nin IN BOOLEAN := TRUE,
        handle_error_in          IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        id_vital_sign_in         IN vital_signs_ea.id_vital_sign%TYPE DEFAULT NULL,
        id_vital_sign_nin        IN BOOLEAN := TRUE,
        id_vital_sign_desc_in    IN vital_signs_ea.id_vital_sign_desc%TYPE DEFAULT NULL,
        id_vital_sign_desc_nin   IN BOOLEAN := TRUE,
        value_in                 IN vital_signs_ea.value%TYPE DEFAULT NULL,
        value_nin                IN BOOLEAN := TRUE,
        id_unit_measure_in       IN vital_signs_ea.id_unit_measure%TYPE DEFAULT NULL,
        id_unit_measure_nin      IN BOOLEAN := TRUE,
        dt_vital_sign_read_in    IN vital_signs_ea.dt_vital_sign_read%TYPE DEFAULT NULL,
        dt_vital_sign_read_nin   IN BOOLEAN := TRUE,
        flg_pain_in              IN vital_signs_ea.flg_pain%TYPE DEFAULT NULL,
        flg_pain_nin             IN BOOLEAN := TRUE,
        id_prof_read_in          IN vital_signs_ea.id_prof_read%TYPE DEFAULT NULL,
        id_prof_read_nin         IN BOOLEAN := TRUE,
        id_prof_cancel_in        IN vital_signs_ea.id_prof_cancel%TYPE DEFAULT NULL,
        id_prof_cancel_nin       IN BOOLEAN := TRUE,
        notes_cancel_in          IN vital_signs_ea.notes_cancel%TYPE DEFAULT NULL,
        notes_cancel_nin         IN BOOLEAN := TRUE,
        flg_state_in             IN vital_signs_ea.flg_state%TYPE DEFAULT NULL,
        flg_state_nin            IN BOOLEAN := TRUE,
        dt_cancel_in             IN vital_signs_ea.dt_cancel%TYPE DEFAULT NULL,
        dt_cancel_nin            IN BOOLEAN := TRUE,
        flg_available_in         IN vital_signs_ea.flg_available%TYPE DEFAULT NULL,
        flg_available_nin        IN BOOLEAN := TRUE,
        id_institution_read_in   IN vital_signs_ea.id_institution_read%TYPE DEFAULT NULL,
        id_institution_read_nin  IN BOOLEAN := TRUE,
        flg_status_epis_in       IN vital_signs_ea.flg_status_epis%TYPE DEFAULT NULL,
        flg_status_epis_nin      IN BOOLEAN := TRUE,
        id_visit_in              IN vital_signs_ea.id_visit%TYPE DEFAULT NULL,
        id_visit_nin             IN BOOLEAN := TRUE,
        id_episode_in            IN vital_signs_ea.id_episode%TYPE DEFAULT NULL,
        id_episode_nin           IN BOOLEAN := TRUE,
        id_patient_in            IN vital_signs_ea.id_patient%TYPE DEFAULT NULL,
        id_patient_nin           IN BOOLEAN := TRUE,
        relation_domain_in       IN vital_signs_ea.relation_domain%TYPE DEFAULT NULL,
        relation_domain_nin      IN BOOLEAN := TRUE,
        id_epis_triage_in        IN vital_signs_ea.id_epis_triage%TYPE DEFAULT NULL,
        id_epis_triage_nin       IN BOOLEAN := TRUE,
        dt_dg_last_update_in     IN vital_signs_ea.dt_dg_last_update%TYPE DEFAULT NULL,
        dt_dg_last_update_nin    IN BOOLEAN := TRUE,
        create_user_in           IN vital_signs_ea.create_user%TYPE DEFAULT NULL,
        create_user_nin          IN BOOLEAN := TRUE,
        create_time_in           IN vital_signs_ea.create_time%TYPE DEFAULT NULL,
        create_time_nin          IN BOOLEAN := TRUE,
        create_institution_in    IN vital_signs_ea.create_institution%TYPE DEFAULT NULL,
        create_institution_nin   IN BOOLEAN := TRUE,
        update_user_in           IN vital_signs_ea.update_user%TYPE DEFAULT NULL,
        update_user_nin          IN BOOLEAN := TRUE,
        update_time_in           IN vital_signs_ea.update_time%TYPE DEFAULT NULL,
        update_time_nin          IN BOOLEAN := TRUE,
        update_institution_in    IN vital_signs_ea.update_institution%TYPE DEFAULT NULL,
        update_institution_nin   IN BOOLEAN := TRUE,
        id_vs_scales_element_in  IN vital_signs_ea.id_vs_scales_element%TYPE DEFAULT NULL,
        id_vs_scales_element_nin IN BOOLEAN := TRUE,
        where_in                 VARCHAR2 DEFAULT NULL,
        handle_error_in          IN BOOLEAN := TRUE,
        rows_out                 IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_vital_sign_in         IN vital_signs_ea.id_vital_sign%TYPE DEFAULT NULL,
        id_vital_sign_nin        IN BOOLEAN := TRUE,
        id_vital_sign_desc_in    IN vital_signs_ea.id_vital_sign_desc%TYPE DEFAULT NULL,
        id_vital_sign_desc_nin   IN BOOLEAN := TRUE,
        value_in                 IN vital_signs_ea.value%TYPE DEFAULT NULL,
        value_nin                IN BOOLEAN := TRUE,
        id_unit_measure_in       IN vital_signs_ea.id_unit_measure%TYPE DEFAULT NULL,
        id_unit_measure_nin      IN BOOLEAN := TRUE,
        dt_vital_sign_read_in    IN vital_signs_ea.dt_vital_sign_read%TYPE DEFAULT NULL,
        dt_vital_sign_read_nin   IN BOOLEAN := TRUE,
        flg_pain_in              IN vital_signs_ea.flg_pain%TYPE DEFAULT NULL,
        flg_pain_nin             IN BOOLEAN := TRUE,
        id_prof_read_in          IN vital_signs_ea.id_prof_read%TYPE DEFAULT NULL,
        id_prof_read_nin         IN BOOLEAN := TRUE,
        id_prof_cancel_in        IN vital_signs_ea.id_prof_cancel%TYPE DEFAULT NULL,
        id_prof_cancel_nin       IN BOOLEAN := TRUE,
        notes_cancel_in          IN vital_signs_ea.notes_cancel%TYPE DEFAULT NULL,
        notes_cancel_nin         IN BOOLEAN := TRUE,
        flg_state_in             IN vital_signs_ea.flg_state%TYPE DEFAULT NULL,
        flg_state_nin            IN BOOLEAN := TRUE,
        dt_cancel_in             IN vital_signs_ea.dt_cancel%TYPE DEFAULT NULL,
        dt_cancel_nin            IN BOOLEAN := TRUE,
        flg_available_in         IN vital_signs_ea.flg_available%TYPE DEFAULT NULL,
        flg_available_nin        IN BOOLEAN := TRUE,
        id_institution_read_in   IN vital_signs_ea.id_institution_read%TYPE DEFAULT NULL,
        id_institution_read_nin  IN BOOLEAN := TRUE,
        flg_status_epis_in       IN vital_signs_ea.flg_status_epis%TYPE DEFAULT NULL,
        flg_status_epis_nin      IN BOOLEAN := TRUE,
        id_visit_in              IN vital_signs_ea.id_visit%TYPE DEFAULT NULL,
        id_visit_nin             IN BOOLEAN := TRUE,
        id_episode_in            IN vital_signs_ea.id_episode%TYPE DEFAULT NULL,
        id_episode_nin           IN BOOLEAN := TRUE,
        id_patient_in            IN vital_signs_ea.id_patient%TYPE DEFAULT NULL,
        id_patient_nin           IN BOOLEAN := TRUE,
        relation_domain_in       IN vital_signs_ea.relation_domain%TYPE DEFAULT NULL,
        relation_domain_nin      IN BOOLEAN := TRUE,
        id_epis_triage_in        IN vital_signs_ea.id_epis_triage%TYPE DEFAULT NULL,
        id_epis_triage_nin       IN BOOLEAN := TRUE,
        dt_dg_last_update_in     IN vital_signs_ea.dt_dg_last_update%TYPE DEFAULT NULL,
        dt_dg_last_update_nin    IN BOOLEAN := TRUE,
        create_user_in           IN vital_signs_ea.create_user%TYPE DEFAULT NULL,
        create_user_nin          IN BOOLEAN := TRUE,
        create_time_in           IN vital_signs_ea.create_time%TYPE DEFAULT NULL,
        create_time_nin          IN BOOLEAN := TRUE,
        create_institution_in    IN vital_signs_ea.create_institution%TYPE DEFAULT NULL,
        create_institution_nin   IN BOOLEAN := TRUE,
        update_user_in           IN vital_signs_ea.update_user%TYPE DEFAULT NULL,
        update_user_nin          IN BOOLEAN := TRUE,
        update_time_in           IN vital_signs_ea.update_time%TYPE DEFAULT NULL,
        update_time_nin          IN BOOLEAN := TRUE,
        update_institution_in    IN vital_signs_ea.update_institution%TYPE DEFAULT NULL,
        update_institution_nin   IN BOOLEAN := TRUE,
        id_vs_scales_element_in  IN vital_signs_ea.id_vs_scales_element%TYPE DEFAULT NULL,
        id_vs_scales_element_nin IN BOOLEAN := TRUE,
        where_in                 VARCHAR2 DEFAULT NULL,
        handle_error_in          IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_vital_sign_read_in   IN vital_signs_ea.id_vital_sign_read%TYPE,
        id_vital_sign_in        IN vital_signs_ea.id_vital_sign%TYPE DEFAULT NULL,
        id_vital_sign_desc_in   IN vital_signs_ea.id_vital_sign_desc%TYPE DEFAULT NULL,
        value_in                IN vital_signs_ea.value%TYPE DEFAULT NULL,
        id_unit_measure_in      IN vital_signs_ea.id_unit_measure%TYPE DEFAULT NULL,
        dt_vital_sign_read_in   IN vital_signs_ea.dt_vital_sign_read%TYPE DEFAULT NULL,
        flg_pain_in             IN vital_signs_ea.flg_pain%TYPE DEFAULT NULL,
        id_prof_read_in         IN vital_signs_ea.id_prof_read%TYPE DEFAULT NULL,
        id_prof_cancel_in       IN vital_signs_ea.id_prof_cancel%TYPE DEFAULT NULL,
        notes_cancel_in         IN vital_signs_ea.notes_cancel%TYPE DEFAULT NULL,
        flg_state_in            IN vital_signs_ea.flg_state%TYPE DEFAULT NULL,
        dt_cancel_in            IN vital_signs_ea.dt_cancel%TYPE DEFAULT NULL,
        flg_available_in        IN vital_signs_ea.flg_available%TYPE DEFAULT NULL,
        id_institution_read_in  IN vital_signs_ea.id_institution_read%TYPE DEFAULT NULL,
        flg_status_epis_in      IN vital_signs_ea.flg_status_epis%TYPE DEFAULT NULL,
        id_visit_in             IN vital_signs_ea.id_visit%TYPE DEFAULT NULL,
        id_episode_in           IN vital_signs_ea.id_episode%TYPE DEFAULT NULL,
        id_patient_in           IN vital_signs_ea.id_patient%TYPE DEFAULT NULL,
        relation_domain_in      IN vital_signs_ea.relation_domain%TYPE DEFAULT NULL,
        id_epis_triage_in       IN vital_signs_ea.id_epis_triage%TYPE DEFAULT NULL,
        dt_dg_last_update_in    IN vital_signs_ea.dt_dg_last_update%TYPE DEFAULT NULL,
        create_user_in          IN vital_signs_ea.create_user%TYPE DEFAULT NULL,
        create_time_in          IN vital_signs_ea.create_time%TYPE DEFAULT NULL,
        create_institution_in   IN vital_signs_ea.create_institution%TYPE DEFAULT NULL,
        update_user_in          IN vital_signs_ea.update_user%TYPE DEFAULT NULL,
        update_time_in          IN vital_signs_ea.update_time%TYPE DEFAULT NULL,
        update_institution_in   IN vital_signs_ea.update_institution%TYPE DEFAULT NULL,
        id_vs_scales_element_in IN vital_signs_ea.id_vs_scales_element%TYPE DEFAULT NULL,
        handle_error_in         IN BOOLEAN := TRUE,
        rows_out                OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_vital_sign_read_in   IN vital_signs_ea.id_vital_sign_read%TYPE,
        id_vital_sign_in        IN vital_signs_ea.id_vital_sign%TYPE DEFAULT NULL,
        id_vital_sign_desc_in   IN vital_signs_ea.id_vital_sign_desc%TYPE DEFAULT NULL,
        value_in                IN vital_signs_ea.value%TYPE DEFAULT NULL,
        id_unit_measure_in      IN vital_signs_ea.id_unit_measure%TYPE DEFAULT NULL,
        dt_vital_sign_read_in   IN vital_signs_ea.dt_vital_sign_read%TYPE DEFAULT NULL,
        flg_pain_in             IN vital_signs_ea.flg_pain%TYPE DEFAULT NULL,
        id_prof_read_in         IN vital_signs_ea.id_prof_read%TYPE DEFAULT NULL,
        id_prof_cancel_in       IN vital_signs_ea.id_prof_cancel%TYPE DEFAULT NULL,
        notes_cancel_in         IN vital_signs_ea.notes_cancel%TYPE DEFAULT NULL,
        flg_state_in            IN vital_signs_ea.flg_state%TYPE DEFAULT NULL,
        dt_cancel_in            IN vital_signs_ea.dt_cancel%TYPE DEFAULT NULL,
        flg_available_in        IN vital_signs_ea.flg_available%TYPE DEFAULT NULL,
        id_institution_read_in  IN vital_signs_ea.id_institution_read%TYPE DEFAULT NULL,
        flg_status_epis_in      IN vital_signs_ea.flg_status_epis%TYPE DEFAULT NULL,
        id_visit_in             IN vital_signs_ea.id_visit%TYPE DEFAULT NULL,
        id_episode_in           IN vital_signs_ea.id_episode%TYPE DEFAULT NULL,
        id_patient_in           IN vital_signs_ea.id_patient%TYPE DEFAULT NULL,
        relation_domain_in      IN vital_signs_ea.relation_domain%TYPE DEFAULT NULL,
        id_epis_triage_in       IN vital_signs_ea.id_epis_triage%TYPE DEFAULT NULL,
        dt_dg_last_update_in    IN vital_signs_ea.dt_dg_last_update%TYPE DEFAULT NULL,
        create_user_in          IN vital_signs_ea.create_user%TYPE DEFAULT NULL,
        create_time_in          IN vital_signs_ea.create_time%TYPE DEFAULT NULL,
        create_institution_in   IN vital_signs_ea.create_institution%TYPE DEFAULT NULL,
        update_user_in          IN vital_signs_ea.update_user%TYPE DEFAULT NULL,
        update_time_in          IN vital_signs_ea.update_time%TYPE DEFAULT NULL,
        update_institution_in   IN vital_signs_ea.update_institution%TYPE DEFAULT NULL,
        id_vs_scales_element_in IN vital_signs_ea.id_vs_scales_element%TYPE DEFAULT NULL,
        handle_error_in         IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN vital_signs_ea%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN vital_signs_ea%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN vital_signs_ea_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN vital_signs_ea_tc,
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
        id_vital_sign_read_in IN vital_signs_ea.id_vital_sign_read%TYPE,
        handle_error_in       IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_vital_sign_read_in IN vital_signs_ea.id_vital_sign_read%TYPE,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
    );

    -- Delete all rows for primary key column ID_VITAL_SIGN_READ
    PROCEDURE del_id_vital_sign_read
    (
        id_vital_sign_read_in IN vital_signs_ea.id_vital_sign_read%TYPE,
        handle_error_in       IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_VITAL_SIGN_READ
    PROCEDURE del_id_vital_sign_read
    (
        id_vital_sign_read_in IN vital_signs_ea.id_vital_sign_read%TYPE,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
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
    PROCEDURE initrec(vital_signs_ea_inout IN OUT vital_signs_ea%ROWTYPE);

    FUNCTION initrec RETURN vital_signs_ea%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN vital_signs_ea_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN vital_signs_ea_tc;

END ts_vital_signs_ea;
/