/*-- Last Change Revision: $Rev: 2028833 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:13 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_p1_data_export AS

    TYPE t_row_list_export IS RECORD(
        id_parent             NUMBER(24),
        label                 VARCHAR2(4000),
        id_req                NUMBER(24),
        id_data_export_config NUMBER(24));

    TYPE t_tbl_list_export IS TABLE OF t_row_list_export;

    TYPE t_data_export_rec IS RECORD(
        id             NUMBER(24),
        id_parent      NUMBER(24),
        id_req         NUMBER(24),
        title          VARCHAR2(1000),
        text           VARCHAR2(1000),
        dt_insert      varchar2(100),
        prof_name      VARCHAR2(1000),
        flg_type       VARCHAR2(10),
        desc_type      VARCHAR2(100),
        flg_status     VARCHAR2(10),
        is_institution NUMBER(24),
        flg_priority   VARCHAR2(10),
        flg_home       VARCHAR2(10));

    TYPE t_tbl_data_export IS TABLE OF t_data_export_rec;

    /**
    * The screen used to export data for the referral shows the items configured 
    * in p1_export_data_config in an hierarchic fashion.
    * One item should only be displayed if there's data available for some of its
    * descendants. 
    *
    * This function evaluates if the provided item has data for any of its descendents
    *
    * @param   i_lang professional language id
    * @param   i_prof professional id, institution and software.
    * @param   i_patient patient id
    * @param   i_episode id    
    * @param   i_dec_row record of p1_data_export_config
    * @param   o_has_descendant. 1 if there data for at least one decendant. 0 otherwise.
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   19-05-2008
    */
    FUNCTION has_descendant
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_dec_row        IN p1_data_export_config%ROWTYPE,
        o_has_descendant OUT NUMBER
    ) RETURN BOOLEAN;

    /**
    * The screen used to export data for the referral shows the items configured 
    * in p1_export_data_config in an hierarchic fashion.
    * One item should only be displayed if there's data available for some of its
    * descendants. 
    *
    * This function evaluates if the provided item has data for any of its descendents
    *
    * @param   i_lang professional language id
    * @param   i_prof professional id, institution and software.
    * @param   i_patient patient id
    * @param   i_episode id    
    * @param   i_ref_type referral type
    * @param   o_has_descendant. 1 if there data for at least one decendant. 0 otherwise.
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   19-05-2008
    */
    FUNCTION has_descendant
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_ref_type IN p1_external_request.flg_type%TYPE
    ) RETURN VARCHAR2;

    /**
    * Returns the data items available for exporting
    *
    * @param   i_lang professional language id
    * @param   i_prof professional id, institution and software.
    * @param   i_patient patient id
    * @param   i_episode id    
    * @param   i_ref_type referral type {*} 'A' analysis {*}'I' image, {*}'E' exam {*}'P' Intervention {*} 'F' PMR Intervention        
    * @param   o_data data items list
    * @param   o_error error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   14-05-2008
    */
    FUNCTION get_data_export_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_ref_type IN p1_external_request.flg_type%TYPE,
        o_data     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_data_export_list
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_ref_type             IN p1_external_request.flg_type%TYPE,
        i_root_name            IN VARCHAR2,
        o_categories_data      OUT pk_types.cursor_type,
        o_elements_data        OUT pk_types.cursor_type,
        o_internal_names_field OUT VARCHAR2,
        o_internal_name_values OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get request types: appointment, analysis, exams, intervention and MFR
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_patient patient id
    * @param   i_episode espisode id        
    * @param   o_type avaible request types on REFERAL
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   30-05-2008
    */
    FUNCTION get_request_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_type    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets request detail based on the data items provided
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof  professional, institution and software ids
    * @param   i_patient              Patient identifier
    * @param   i_episode              Episode identifier
    * @param   i_data_export list of items (as in p1_data_export_config) to include in the request
    * @param   i_ref_type             Referral type 
    * @param   O_DETAIL Request general data
    * @param   o_text                 Referral information detail: Reason, Symptomology, Progress, History, Family history,
    *                                  Objective exam, Diagnostic exams and Notes (mcdts)   
    * @param   o_problem              Referral problems information
    * @param   o_diagnosis            Referral diagnosis information
    * @param   o_mcdt                 MCDT data   
    * @param   O_ERROR
    *
    * @value   i_flg_type             {*} 'C' - Appointments {*} 'A'  - Lab tests {*} 'I' - Imaging exams {*} 'E' - Other exams
    *                                 {*} 'P' - Procedures {*} 'F' -  Rehabilitation {*} 'S'  - Surgery requests
    *                                 {*} 'N' - Admission requests
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   23-05-2008
    */
    FUNCTION get_p1_detail_new
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_data_export  IN table_table_number,
        i_ref_type     IN p1_external_request.flg_type%TYPE,
        o_detail       OUT pk_types.cursor_type,
        o_text         OUT pk_types.cursor_type,
        o_problem      OUT pk_types.cursor_type,
        o_diagnosis    OUT pk_types.cursor_type,
        o_mcdt         OUT pk_types.cursor_type,
        o_notes_adm    OUT pk_types.cursor_type,
        o_needs        OUT pk_types.cursor_type,
        o_info         OUT pk_types.cursor_type,
        o_notes_status OUT pk_types.cursor_type,
        o_answer       OUT pk_types.cursor_type,
        o_title_status OUT VARCHAR2,
        o_editable     OUT VARCHAR2,
        o_can_cancel   OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_p1_data_export
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        i_data_export    IN table_table_number,
        i_ref_type       IN p1_external_request.flg_type%TYPE,
 /*       o_detail         OUT pk_types.cursor_type,
        o_text           OUT pk_types.cursor_type,
        o_diagnosis      OUT pk_types.cursor_type,
        o_mcdt           OUT pk_types.cursor_type,
        o_notes_adm      OUT pk_types.cursor_type,
        o_needs          OUT pk_types.cursor_type,
        o_info           OUT pk_types.cursor_type,
        o_notes_status   OUT pk_types.cursor_type,
        o_answer         OUT pk_types.cursor_type,
        o_title_status   OUT VARCHAR2,
        o_editable       OUT VARCHAR2,
        o_can_cancel     OUT VARCHAR2,*/
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    /**
    * Get all available specialities for requests
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof  professional, institution and software ids
    * @param   i_patient patient id, to filter by sex and age
    * @param   o_sql canceling reason id
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   22-05-2008
    */
    FUNCTION get_clinical_service
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_sql     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_clinical_service
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_tbl_core_domain;
    /**
    * Get all available clinical institutions  ALERT-158599
    *
    * @param   i_lang            language associated to the professional executing the request
    * @param   i_prof            professional, institution and software ids
    * @param   i_p1_spec         P1_speciality
    * @param   o_sql             clinical institutions
    * @param   o_error an error  message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   31-01-2011
    */
    FUNCTION get_clinical_institution
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_p1_spec IN p1_speciality.id_speciality%TYPE,
        o_sql     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_clinical_institution
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_spec IN p1_speciality.id_speciality%TYPE
    ) RETURN t_tbl_core_domain;
    /**
    * Get patient mcdt
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_episode episode id    
    * @param   i_patient patient id
    *
    * @RETURN  Return table (t_coll_p1_export_data) pipelined
    * @author  Joana Barroso
    * @version 1.0
    * @since   25-06-2008
    * @modify  Joana Barroso 22-07-2008 new input param i_ref_type
    */

    FUNCTION get_pat_mcdt
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis    IN analysis_req.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_coll_p1_export_data
        PIPELINED;

    /**
    * Get patient analysis
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_episode episode id    
    * @param   i_patient patient id    
    *
    * @RETURN  Return table (t_coll_p1_export_data) pipelined
    * @author  Joana Barroso
    * @version 1.0
    * @since   20-05-2008
    */
    /*
    FUNCTION get_pat_analysis
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis    IN analysis_req.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_coll_p1_export_data
        PIPELINED;
    */

    /**
    * Get patient exams
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_episode episode id    
    * @param   i_patient patient id    
    * @param   i_exam_type  Exam type {*} 'I' Image {*} 'E' Other Exams
    *
    * @RETURN  Return table (t_coll_p1_export_data) pipelined
    * @author  Joana Barroso
    * @version 1.0
    * @since   20-05-2008
    */
    /*
    FUNCTION get_pat_exam
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis      IN exam_req.id_episode%TYPE,
        i_patient   IN patient.id_patient%TYPE,
        i_exam_type IN exam.flg_type%TYPE -- imagem 'I' ou outros exames 'E'
    ) RETURN t_coll_p1_export_data
        PIPELINED;
    */

    /**
    * Get patient interventions
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_episode episode id    
    * @param   i_patient patient id    
    *
    * @RETURN  Return table (t_coll_p1_export_data) pipelined
    * @author  Joana Barroso
    * @version 1.0
    * @since   20-05-2008
    */
    /*
    FUNCTION get_pat_interv
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis    IN exam_req.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_coll_p1_export_data
        PIPELINED;
        */

    /**
    * Get patient mfr interventions
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_episode episode id    
    * @param   i_patient patient id    
    *
    * @RETURN  Return table (t_coll_p1_export_data) pipelined
    * @author  Joana Barroso
    * @version 1.0
    * @since   20-05-2008
    */
    /*
    FUNCTION get_pat_interv_mfr
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis    IN exam_req.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_coll_p1_export_data
        PIPELINED;
    */

    /**
    * Get patient active problems list
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof    Professional, institution and software ids
    * @param   i_patient Patient identifier
    * @param   i_status  Status problem
    * @param   i_type    Problem type     
    *
    * @value   i_type    {*} 'D' Relevant Disease; {*} 'P' Problems; {*} 'A' Allergies
    *
    * @RETURN  Return table (t_coll_p1_export_data) pipelined
    * @author  Joao Sa
    * @version 1.0
    * @since   14-05-2008
    */
    FUNCTION get_pat_problem
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_status  IN VARCHAR2,
        i_type    IN VARCHAR2
    ) RETURN t_coll_p1_export_data
        PIPELINED;

    /**
    * Get patient diagnosis
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof    Professional, institution and software ids
    * @param   i_epis    Episode identifier
    * @param   i_patient Patient identifier
    *
    * @RETURN  Return table (t_coll_p1_export_data) pipelined
    * @author  Joana Barroso
    * @version 1.0
    * @since   20-05-2008
    */
    FUNCTION get_pat_diagnosis
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis    IN exam_req.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_coll_p1_export_data
        PIPELINED;

    /**
    * Gets all analysis with results of a patient
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software    
    * @param   i_patient patient id    
    *
    * @RETURN  Return table (t_coll_p1_export_data) pipelined
    * @author  Joana Barroso
    * @version 1.0
    * @since   21-05-2008
    */

    FUNCTION get_pat_analysis_req
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis    IN analysis_req.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_coll_p1_export_data
        PIPELINED;

    /**
    * Gets all exams with results of a patient
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software    
    * @param   i_patient patient id 
    * @param   i_exam_type {*}'I' image {*}'E' Exam
    *
    * @RETURN  Return table (t_coll_p1_export_data) pipelined
    * @author  Joana Barroso
    * @version 1.0
    * @since   26-05-2008
    */
    /*
    FUNCTION get_pat_exam_req
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis      IN exam_req.id_episode%TYPE,
        i_patient   IN patient.id_patient%TYPE,
        i_exam_type IN exam.flg_type%TYPE
    ) RETURN t_coll_p1_export_data
        PIPELINED;
        */

    /**
    * Interventions requests for a given episode
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software    
    * @param   i_patient patient id 
    * @param   i_epis episode id
    *
    * @RETURN  Return table (t_coll_p1_export_data) pipelined
    * @author  Joana Barroso
    * @version 1.0
    * @since   27-05-2008
    */
    /*
    FUNCTION get_pat_interv_req
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis    IN exam_req.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE
        
    ) RETURN t_coll_p1_export_data
        PIPELINED;
        */

    /**
    * PMR Interventions requests for a given episode
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software    
    * @param   i_patient patient id 
    * @param   i_epis episode id
    *
    * @RETURN  Return table (t_coll_p1_export_data) pipelined
    * @author  Joana Barroso
    * @version 1.0
    * @since   29-05-2008
    */
    /*
    FUNCTION get_pat_interv_mfr_req
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis    IN exam_req.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE
        
    ) RETURN t_coll_p1_export_data
        PIPELINED;
        */

    /**
    * Gets vitals signs of a patient
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software    
    * @param   i_episode episode id
    * @param   i_patient patient id 
    *
    * @RETURN  Return table (t_coll_p1_export_data) pipelined
    * @author  Joana Barroso
    * @version 1.0
    * @since   26-05-2008
    */
    FUNCTION get_pat_vital_sign
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis    IN exam_req.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_coll_p1_export_data
        PIPELINED;

    /**
    * Get data for the past history for the doc_area provided
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_episode episode id    
    * @param   i_patient patient id    
    * @param   i_doc_area doc area id
    *
    * @RETURN  Return table (t_coll_p1_export_data) pipelined
    * @author  Joao Sa
    * @version 1.0
    * @since   14-05-2008
    */
    FUNCTION get_past_hist_all
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_doc_area IN doc_area.id_doc_area%TYPE
    ) RETURN t_coll_p1_export_data
        PIPELINED;

    /**
    * Get data for patient medication
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_episode episode id    
    * @param   i_patient patient id  
    * @param   i_type    Prescription type
    *
    * @RETURN  Return table (t_coll_p1_export_data) pipelined
    * @author  Joana Barroso
    * @version 2.5.2.3
    * @since   31-05-2012
    */
    FUNCTION get_pat_medication
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_type    IN VARCHAR2
    ) RETURN t_coll_p1_export_data
        PIPELINED;

END pk_p1_data_export;
/
