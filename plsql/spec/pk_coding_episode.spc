/*-- Last Change Revision: $Rev: 2013161 $*/
/*-- Last Change by: $Author: humberto.cardoso $*/
/*-- Date of last change: $Date: 2022-04-26 22:40:43 +0100 (ter, 26 abr 2022) $*/
CREATE OR REPLACE PACKAGE pk_coding_episode IS

    -- Author  : HUMBERTO.CARDOSO
    -- Created : 02/01/2022 11:22:18
    -- Purpose : 

    -- Get the episodes list for the specified date
    -- Date format is: '20211216000000'
    -- Id_professional can be null: eg: profissional(NULL, 11111, 1);
    FUNCTION get_episodes_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_dt       IN VARCHAR2,
        o_episodes OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    -- Get the patient data
    -- Only one record is returned
    FUNCTION get_patient_data
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN NUMBER,
        o_patient_data OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    -- Get the patient social attibutes
    -- Only one record is returned
    FUNCTION get_pat_soc_attributes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN NUMBER,
        o_soc_attributes OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    -- Get the episode/patient health plans
    -- Can be returned multiple records
    -- Health plans associated with the patient and episode are returned
    -- The column EPISODE_STATUS identifies if the health plan is associated with the episode
    -- The column FLG_PRIMARY identifies the record selected for billing
    FUNCTION get_epis_health_plans
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN NUMBER,
        i_id_patient        IN NUMBER,
        o_epis_health_plans OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

END pk_coding_episode;
/
