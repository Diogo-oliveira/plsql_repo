/*-- Last Change Revision: $Rev: 2028571 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:35 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_complication IS

    -- Author  : PEDRO.TEIXEIRA
    -- Created : 14/10/2017 14-10-2017 1924:01:34 19:01357r
    -- Purpose : Handle complication and the relations with diagnosis

    g_complication_inactive CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_complication_active   CONSTANT VARCHAR2(1 CHAR) := 'A';

    PROCEDURE set_diag_complications_h
    (
        i_epis_diagnosis   IN NUMBER,
        i_epis_diagnosis_h IN NUMBER
    );

    /***************************************************************************************
    ***************************************************************************************/
    FUNCTION set_epis_diag_complications
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_epis_diagnosis         IN pk_edis_types.rec_in_epis_diagnosis,
        i_id_epis_diagnosis      IN epis_diagnosis.id_epis_diagnosis%TYPE DEFAULT NULL,
        i_id_epis_diagnosis_hist IN epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE DEFAULT NULL,
        i_dt_record              IN epis_diag_complications.dt_create%TYPE DEFAULT NULL,
        io_params                IN OUT NOCOPY pk_edis_types.table_out_epis_diags,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************
    ***************************************************************************************/
    FUNCTION get_epis_diag_complications
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_diagnosis   IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_id_epis_diagnosis_h IN NUMBER
    ) RETURN pk_edis_types.table_out_complications;

    /***************************************************************************************
    ***************************************************************************************/
    FUNCTION get_complications_desc_serial
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_complication_and_diag
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_patient    IN patient.id_patient%TYPE,
        o_complications OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

END pk_complication;
/
