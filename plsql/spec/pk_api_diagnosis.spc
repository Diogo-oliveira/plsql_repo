/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_api_diagnosis IS

    -- Author  : Rui Spratley
    -- Created : 23-05-2008
    -- Purpose : API for INTER_ALERT

    /** @headcom
    * Public Function. Obter o descritivo dos diagnósticos associados a uma requisição.
    * Não é chamada pelo Flash.
    *
    * @param      I_LANG               Língua registada como preferência do profissional
    * @param      I_EXAM_REQ     ID da requisição de exames.
    * @param      I_ANALYSIS_REQ   ID da requisição de análises.
    * @param      I_INTERV_PRESC   ID da requisição de procedimentos.
    * @param      I_DRUG_PRESC     ID da requisição de medicamentos.
    * @param      I_DRUG_REQ     ID da requisição de medicamentos à farmácia.
    * @param      I_PRESCRIPTION   ID da prescrição de medicamentos para o exterior.
    * @param      I_PRESCRIPTION_USA   ID da prescrição de medicamentos para o exterior (versão USA).
    * @param      I_PROF         object (ID do profissional, ID da instituição, ID do software)
    *
    * @return     boolean
    * @author     SS
    * @version    0.1
    * @since      2007/02/06
    */

    FUNCTION intf_concat_diag
    (
        i_lang             IN language.id_language%TYPE,
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_drug_presc       IN NUMBER, -- filed not used
        i_drug_req         IN NUMBER, -- filed not used
        i_prescription     IN NUMBER, -- filed not used
        i_prescription_usa IN NUMBER, -- filed not used
        i_prof             IN profissional
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns the diagnosis associated with a request.
    *
    * @param i_lang              Língua registada como preferência do profissional
    * @param i_exam_req_det      ID da requisição de exames.
    * @param i_analysis_req_det  ID da requisição de análises.
    * @param i_interv_presc_det  ID da requisição de procedimentos.
    * @param i_drug_presc        ID da requisição de medicamentos.
    * @param i_drug_req          ID da requisição de medicamentos à farmácia.
    * @param i_prescription      ID da prescrição de medicamentos para o exterior.
    * @param o_id_diagnosis      Lista dos identificadores do diagnosis
    * @param o_desc_diagnosis    Lista da descricao dos diagnostico
    * @param o_error             Error message    
    *
    * @return                    True if everything was ok. False otherwise.
    * 
    * @author                    Rui Salgado
    * @version                   1.0
    * @since                     2007/06/21
    ********************************************************************************************/
    FUNCTION get_mcdts_diagnosis_intf
    (
        i_lang             IN language.id_language%TYPE,
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_drug_presc       IN NUMBER, -- field not used
        i_drug_req         IN NUMBER, -- field not used
        i_prescription     IN NUMBER, -- field not used
        i_prof             IN profissional,
        o_diagnosis        OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Registar os diagnósticos diferenciais(provisórios) ou finais de um episódio
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_prof_cat_type          category of professional
    * @param i_epis                   episode id
    * @param i_id_diag                diagnosis id
    * @param i_diag_status            Array com estados dos diagnósticos
    * @param i_spec_notes             Array com as notas especificas de cada diagnóstico
    * @param i_flg_type               Tipo de registo: P - Provisório; D - Definitivo
    * @param i_desc_diagnosis         descrição do diagnóstico quando é seleccionado a opção OUTRO
    * @param i_flg_final_type         Tipo de diagnóstico de saída: primário ou secondário
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/05
    **********************************************************************************************/
    FUNCTION intf_create_diag
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        i_id_diag        IN table_number,
        i_diag_status    IN table_varchar,
        i_spec_notes     IN table_varchar,
        i_flg_type       IN table_varchar,
        i_desc_diagnosis IN table_varchar,
        i_id_alert_diag  IN table_number,
        i_flg_final_type IN table_varchar,
        i_epis_diag_date IN table_varchar,
        o_epis_diagnosis OUT table_number,
        o_epis_diag_hist OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * API used by the referral to register a diagnosis
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_prof_cat_type          category of professional
    * @param i_epis                   episode id
    * @param i_id_diag                diagnosis id
    * @param i_diag_status            Diagnosis status array
    * @param i_spec_notes             Specific notes array for each diagnosis
    * @param i_desc_diagnosis         Diagnosis description when registered in free text
    * @param i_notes                  General notes associated to all the diagnosis
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        2.6.1.2
    * @since                          2011/09/20
    **********************************************************************************************/
    FUNCTION ref_create_diag_no_commit
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        i_id_diag        IN table_number,
        i_diag_status    IN table_varchar,
        i_spec_notes     IN table_varchar,
        i_desc_diagnosis IN table_varchar,
        i_notes          IN epis_diagnosis_notes.notes%TYPE,
        i_id_alert_diag  IN table_number,
        i_sysdate        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_epis_diagnosis OUT table_number,
        o_epis_diag_hist OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that returns diagnosis for an episode
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_id_episode             episode ID
    *
    * @param o_diag                   Cursor with diagnoses' information
    * @param o_error                  Error message
    *
    * @return                         true or false para sucesso ou erro
    *
    * @author                         José Silva
    * @version                        2.6.1.2
    * @since                          2011/08/16
    **********************************************************************************************/
    FUNCTION get_epis_diag
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_diag    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that returns diagnosis based on an record of Episode diagnosis records
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_epis_diag              Array of episode diagnosis ID
    * @param i_epis_diag_hist         Show cancelled/rulled out records: (Y)es or (N)o
    *
    * @return                         Diagnosis list (pipelined)
    *
    * @author                         José Silva
    * @version                        2.6.1.2  
    * @since                          2011/09/20
    **********************************************************************************************/
    FUNCTION get_ref_epis_diag
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_diag      IN table_number,
        i_epis_diag_hist IN table_number
    ) RETURN t_coll_epis_diagnosis
        PIPELINED;

    /**********************************************************************************************
    * Get the most recent note registered in the episode 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_episode                episode ID
    * @param i_epis_diag              episode diagnosis ID
    * @param i_epis_diag_hist         episode diagnosis ID (history record)
    *
    * @return                         diagnosis note
    *                        
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          29-02-2012
    **********************************************************************************************/
    FUNCTION get_epis_diag_note
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_diag      IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_epis_diag_hist IN epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE
    ) RETURN epis_diagnosis.notes%TYPE;

    /**
    * Get the concept version ids associated with a concept
    *
    * @param   i_concept          Concept ID
    *
    * @return  Concept version IDs
    *
    * @author  José Silva
    * @version v2.6.2
    * @since   04/Jun/2012
    */
    FUNCTION get_id_concept_version(i_concept IN diagnosis.id_concept%TYPE) RETURN table_number;

    /**
    * Get the concept id associated with a concept version
    *
    * @param   i_concept_version          Concept version ID
    *
    * @return  Concept ID
    *
    * @author  José Silva
    * @version v2.6.2
    * @since   04/Jun/2012
    */
    FUNCTION get_id_concept(i_concept_version IN diagnosis.id_diagnosis%TYPE) RETURN diagnosis.id_concept%TYPE;

    /* Stores log error messages. */
    g_error VARCHAR2(32000);
    /* Stores the package name. */
    g_package_name VARCHAR2(32);
    /* Message code for an unexpected exception. */
    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';

END pk_api_diagnosis;
/
