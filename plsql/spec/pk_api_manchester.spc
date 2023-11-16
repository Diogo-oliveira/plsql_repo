/*-- Last Change Revision: $Rev: 2028473 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:01 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_manchester AS

    FUNCTION get_offline_ext_sys RETURN NUMBER;

    TYPE rec_episode IS RECORD(
        id_episode      NUMBER,
        dt_begin        DATE,
        dt_end          DATE,
        flg_status      VARCHAR2(1),
        id_institution  NUMBER,
        id_patient      NUMBER,
        id_professional NUMBER,
        id_room         NUMBER);

    TYPE rec_discharge IS RECORD(
        id_discharge       NUMBER,
        id_disch_reas_dest NUMBER,
        id_episode         NUMBER,
        dt_cancel          DATE,
        id_prof_cancel     NUMBER,
        notes_cancel       VARCHAR2(4000),
        id_prof_med        NUMBER,
        dt_med             DATE,
        notes_med          VARCHAR2(4000),
        id_prof_admin      NUMBER,
        dt_admin           DATE,
        notes_admin        VARCHAR2(4000),
        flg_status         VARCHAR2(1),
        id_transp_ent_med  NUMBER,
        id_transp_ent_adm  NUMBER,
        flg_pat_condition  VARCHAR2(1));

    TYPE rec_epis_triage IS RECORD(
        id_epis_triage         NUMBER,
        id_episode             NUMBER,
        id_triage_color        NUMBER,
        id_triage              NUMBER,
        id_professional        NUMBER,
        dt_begin               DATE,
        dt_end                 DATE,
        flg_letter             VARCHAR2(1),
        notes                  VARCHAR2(4000),
        id_necessity           table_number,
        id_origin              NUMBER,
        id_triage_white_reason NUMBER,
        desc_origin            VARCHAR2(200),
        end_triage_notes       VARCHAR2(4000),
        emergency_contact      VARCHAR2(200),
        id_transp_entity       NUMBER,
        tab_triage             table_number,
        tab_tri_disc_consent   table_number);

    TYPE rec_vital_sign_read IS RECORD(
        id_vital_sign_read   NUMBER,
        dt_vital_sign_read   DATE,
        id_vital_sign        NUMBER,
        id_vital_sign_desc   NUMBER,
        id_episode           NUMBER,
        valor                NUMBER,
        flg_state            VARCHAR2(1),
        id_prof_read         NUMBER,
        id_unit_measure      NUMBER,
        id_epis_triage       NUMBER,
        id_vs_scales_element NUMBER);

    TYPE rec_movement IS RECORD(
        id_movement     NUMBER,
        id_episode      NUMBER,
        id_prof_request NUMBER,
        id_prof_move    NUMBER,
        dt_begin        DATE,
        dt_end          DATE,
        dt_req          DATE,
        flg_status      VARCHAR2(1),
        id_room_from    NUMBER,
        id_room_to      NUMBER);

    TYPE rec_patient IS RECORD(
        id_paciente     NUMBER,
        nome            VARCHAR2(200),
        sexo            VARCHAR2(1),
        data_nascimento DATE,
        idade           NUMBER,
        naturalidade    VARCHAR2(100),
        id_pais         NUMBER,
        cartao_sus      VARCHAR2(30),
        rg              VARCHAR2(20),
        cpf             VARCHAR2(11),
        logradouro      VARCHAR2(80),
        cidade          VARCHAR2(80),
        bairro          VARCHAR2(80),
        estado          VARCHAR2(200),
        cep             VARCHAR2(10),
        fone1           VARCHAR2(20),
        fone2           VARCHAR2(20),
        nome_pai        VARCHAR2(100),
        nome_mae        VARCHAR2(100),
        profissao       VARCHAR2(100),
        id_scholarship  NUMBER,
        fotografia      BLOB,
        dt_fotografia   DATE,
        id_health_plan  NUMBER,
        marital_status  VARCHAR2(1),
        flg_job_status  VARCHAR2(1),
        id_professional NUMBER);

    TYPE rec_professional IS RECORD(
        id_professional NUMBER,
        name            VARCHAR2(200),
        nick_name       VARCHAR2(200),
        dt_birth        DATE,
        address         VARCHAR2(200),
        district        VARCHAR2(200),
        city            VARCHAR2(200),
        zip_code        VARCHAR2(200),
        num_contact     VARCHAR2(30),
        marital_status  VARCHAR2(240),
        gender          VARCHAR2(1),
        flg_state       VARCHAR2(1),
        num_order       VARCHAR2(30),
        id_scholarship  NUMBER,
        id_speciality   NUMBER,
        id_country      NUMBER,
        adw_last_update DATE,
        barcode         VARCHAR2(30),
        initials        VARCHAR2(5),
        title           VARCHAR2(6),
        short_name      VARCHAR2(200),
        cell_phone      VARCHAR2(20),
        fax             VARCHAR2(20),
        email           VARCHAR2(100),
        first_name      VARCHAR2(100),
        middle_name     VARCHAR2(100),
        last_name       VARCHAR2(100),
        work_phone      VARCHAR2(20),
        upin            VARCHAR2(30),
        dea             VARCHAR2(30),
        flg_migration   VARCHAR2(1),
        flg_prof_test   VARCHAR2(1),
        prof_cat        NUMBER,
        desc_user       VARCHAR2(200),
        pass_user       VARCHAR2(4000),
        secret_quest    VARCHAR2(2),
        secret_answ     VARCHAR2(400),
        date_creation   DATE,
        flg_status      VARCHAR2(1),
        img_photo       BLOB,
        dt_photo_tstz   DATE);

    TYPE rec_prof_institution IS RECORD(
        id_prof_institution NUMBER,
        id_professional     NUMBER,
        id_institution      NUMBER,
        flg_state           VARCHAR2(1),
        dt_begin            DATE,
        dt_end              DATE,
        num_mecan           VARCHAR2(30));

    --
    /********************************************************************************************
    * Creates a new episode
    * Affected tables: VISIT, EPISODE, EPIS_INFO
    *
    * @param i_lang                language ID
    * @param i_institution         institution ID
    * @param i_episode             episode record from Offline DB
    * @param o_episode             New episode ID 
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      José Silva
    * @since                       2009/10/22
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION set_episode
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_episode     IN rec_episode,
        o_episode     OUT episode.id_episode%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Creates a new triage
    * Affected tables: EPIS_TRIAGE, EPIS_ANAMNESIS
    *
    * @param i_lang                language ID
    * @param i_institution         institution ID
    * @param i_epis_triage         triage record from Offline DB
    * @param o_epis_triage         New triage ID 
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      José Silva
    * @since                       2009/10/22
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION set_epis_triage
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_epis_triage IN rec_epis_triage,
        o_epis_triage OUT epis_triage.id_epis_triage%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Creates a new vital sign read
    * Affected tables: VITAL_SIGN_READ
    *
    * @param i_lang                language ID
    * @param i_institution         institution ID
    * @param i_vs_read             vital sign record from Offline DB
    * @param o_vs_id               New vital sign read ID 
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      José Silva
    * @since                       2009/10/22
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION set_vital_sign_read
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_epis_triage IN rec_epis_triage,
        i_vs_read     IN rec_vital_sign_read,
        o_vs_id       OUT vital_sign_read.id_vital_sign_read%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Creates a new movement
    * Affected tables: MOVEMENT
    *
    * @param i_lang                language ID
    * @param i_institution         institution ID
    * @param i_movement            movement record from Offline DB
    * @param o_movement            New movement ID
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      José Silva
    * @since                       2009/10/22
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION set_movement
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_movement    IN rec_movement,
        o_movement    OUT movement.id_movement%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Creates a new discharge
    * Affected tables: DISCHARGE, DISCHARGE_DETAIL
    *
    * @param i_lang                language ID
    * @param i_institution         institution ID
    * @param i_discharge           discharge record from Offline DB
    * @param o_discharge           New discharge ID 
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      José Silva
    * @since                       2009/10/22
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION set_discharge
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_discharge   IN rec_discharge,
        o_discharge   OUT discharge.id_discharge%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**######################################################
      GLOBALS
    ######################################################**/
    g_owner   VARCHAR2(50);
    g_package VARCHAR2(50);
    --
    g_error VARCHAR2(4000);
    g_exception EXCEPTION;
    --
    g_yes    CONSTANT VARCHAR2(1) := 'Y';
    g_no     CONSTANT VARCHAR2(1) := 'N';
    g_active CONSTANT VARCHAR2(1) := 'A';
    --
    g_epis_type_offline     CONSTANT epis_type.id_epis_type%TYPE := 9;
    g_software_offline      CONSTANT software.id_software%TYPE := 29;
    g_software_triage       CONSTANT software.id_software%TYPE := 35;
    g_prof_template_offline CONSTANT profile_template.id_profile_template%TYPE := 403;
    g_lang_offline          CONSTANT language.id_language%TYPE := 11;
    g_dateformat            CONSTANT VARCHAR2(2000) := 'YYYYMMDDhh24miss';

    g_disch_type_f      CONSTANT discharge.flg_type%TYPE := 'F';
    g_disch_type_triage CONSTANT discharge.flg_type_disch%TYPE := 'T';
    g_dcs_selected      CONSTANT prof_dep_clin_serv.flg_status%TYPE := 'S';

    -- Movemnt types (M - movement and D - Detour)
    g_mov_type_movement CONSTANT VARCHAR2(1) := 'M';
    g_mov_type_detour   CONSTANT VARCHAR2(1) := 'D';

END pk_api_manchester;
/
