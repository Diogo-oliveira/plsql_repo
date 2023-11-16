/*-- Last Change Revision: $Rev: 2028531 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:20 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_barcode IS

    FUNCTION generate_barcode_checkdigit
    (
        i_lang    IN language.id_language%TYPE,
        i_barcode IN VARCHAR2,
        o_barcode OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION generate_barcode
    (
        i_lang         IN language.id_language%TYPE,
        i_barcode_type IN VARCHAR2,
        i_institution  IN NUMBER,
        i_software     IN NUMBER,
        o_barcode      OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Listar o episódio clinico associado ao código de barras pesquisado
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_barcode                Código de barras a pesquisar                   
    * @param o_result                 devolve o episódio clinico associado ao código de barras ou a mensagem de erro 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/06/26
    **********************************************************************************************/
    FUNCTION get_grid_barcode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_barcode IN episode.barcode%TYPE,
        o_result  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Retorna o código de barras da instituição 
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_institution            instituição                  
    * @param o_institution_barcode    devolve o código de barras da instituição 
    * @param o_error                  Error message
    *
    * @author                         Rui Duarte
    * @version                        1.0 
    * @since                          2009/11/06
    **********************************************************************************************/

    FUNCTION get_institution_barcode
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_institution         IN institution.id_institution%TYPE,
        o_institution_barcode OUT institution.barcode%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * Validates a scanned barcode against a given patient and episode                                                                          *
    *                                                                                                                                          *
    * @param I_LANG                   LANGUAGE                                                                                                 *
    * @param I_PROF                   PROFESSIONAL ARRAY                                                                                       *
    * @param I_ID_PATIENT             Patient Identification                                                                                   *
    * @param I_ID_EPISODE             Episode Identification                                                                                   *
    * @param I_BARCODE                Scanned barcode                                                                                          *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         boolean                                                                                                  *
    * @raises                                                                                                                                  *
    *                                                                                                                                          *
    * @author                         Nelson Canastro                                                                                          *
    * @version                         1.0                                                                                                     *
    * @since                          2010/05/24                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION validate_patient_barcode
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_barcode    IN VARCHAR2,
        o_summary    OUT VARCHAR2,
        o_result     OUT VARCHAR2,
        o_patient    OUT patient.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets patient barcode
    *
    * @param i_lang          language id
    * @param i_prof          professional, software and institution ids
    * @param i_episode       episode id                  
    *
    * @return                Patient barcode 
    * 
    * @raises                PL/SQL generic errors "OTHERS"
    *
    * @author                Alexandre Santos
    * @version               v1.0 
    * @since                 2010/09/20
    *********************************************************************************************/
    FUNCTION get_pat_barcode
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_patient              IN patient.id_patient%TYPE DEFAULT NULL,
        i_barcode              IN episode.barcode%TYPE DEFAULT NULL,
        i_num_clin_record      IN clin_record.num_clin_record%TYPE DEFAULT NULL,
        i_val_external_barcode IN sys_config.value%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;
    --
    --
    g_error        VARCHAR2(4000);
    g_sysdate      DATE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;
    g_epis_active  episode.flg_status%TYPE;
    g_med_barcode_reason_area CONSTANT cancel_rea_area.intern_name%TYPE := 'MEDICATION_BARCODE';

    --
    g_exception      EXCEPTION;
    g_exception_user EXCEPTION;
    g_action_type_user    CONSTANT VARCHAR2(1) := 'U';
    g_action_type_system  CONSTANT VARCHAR2(1) := 'S';
    g_action_type_default CONSTANT VARCHAR2(1) := 'D';

    g_cfg_external_barcode CONSTANT sys_config.id_sys_config%TYPE := 'EXTERNAL_BARCODE';
    g_ext_bar_cr           CONSTANT sys_config.value%TYPE := 'CR'; --CLIN_RECORD.NUM_CLIN_RECORD
    g_ext_bar_nhs          CONSTANT sys_config.value%TYPE := 'NHS'; --PAT_SOC_ATTRIBUTES.NATIONAL_HEALTH_NUMBER
    g_ext_bar_na           CONSTANT sys_config.value%TYPE := 'NA'; --EPISODE.BARCODE

    FUNCTION get_barcode_cfg
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_code_cf IN VARCHAR2
    ) RETURN v_barcode_type_cfg%ROWTYPE;

    FUNCTION get_barcode_cfg_base
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_code_cf IN VARCHAR2
    ) RETURN t_tbl_barcode_type_cfg;

END;
/
