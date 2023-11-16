/*-- Last Change Revision: $Rev: 2028601 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:48 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_diagnosis_ux IS

    -- Author  : ALEXANDRE.SANTOS
    -- Created : 20-01-2012 08:40:34
    -- Purpose : Diagnosis API's called by UX layer

    -- Public type declarations
    --type <TypeName> is <Datatype>;

    -- Public constant declarations
    --<ConstantName> constant <Datatype> := <Value>;

    -- Public variable declarations
    --<VariableName> <Datatype>;

    -- Public function and procedure declarations
    --function <FunctionName>(<Parameter> <Datatype>) return <Datatype>;

    /**
    * Get dynamic screen sections and events list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_diagnosis                 Diagnosis id
    * @param   o_diag_ds_int_name          Dynamic screen internal name
    * @param   o_min_tumor_num             Minimum tumor number
    * @param   o_section                   Section cursor
    * @param   o_def_events                Def events cursor
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   17-01-2012
    */
    FUNCTION get_section_events_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_diagnosis        IN concept_version.id_concept_version%TYPE,
        o_diag_ds_int_name OUT ds_component.internal_name%TYPE,
        o_min_tumor_num    OUT epis_diag_tumors.tumor_num%TYPE,
        o_section          OUT pk_types.cursor_type,
        o_def_events       OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get dynamic screen sections and events list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_diag                 episode diagnosis ID
    * @param   i_epis_diag_hist            episode diagnosis ID (history record)
    * @param   o_diag_ds_int_name          Dynamic screen internal name
    * @param   o_min_tumor_num             Minimum tumor number
    * @param   o_section                   Section cursor
    * @param   o_def_events                Def events cursor
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   17-01-2012
    */
    FUNCTION get_section_events_list
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_epis_diagnosis      IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_epis_diagnosis_hist IN epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE,
        o_diag_ds_int_name    OUT ds_component.internal_name%TYPE,
        o_min_tumor_num       OUT epis_diag_tumors.tumor_num%TYPE,
        o_section             OUT pk_types.cursor_type,
        o_def_events          OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get dynamic screen sections and events list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_params                    Group of parameters
    * @param   o_section                   Section cursor
    * @param   o_def_events                Default events cursor
    * @param   o_events                    Events cursor
    * @param   o_items_values              Item values for multichoices of single choice
    * @param   o_data_val                  Default data or previous saved data
    * @param   o_error                     Error information
    *
    * @example i_params                    Example of the XML passed in this variable
    *          <PARAMETERS ID_EPISODE="" ID_PATIENT="">
    *              <!-- ID_EPIS_DIAGNOSIS is only needed when editing the current episode diagnosis, in the case of cancer diagnosis also means editing the current staging diagnosis
    *                   ID_EPIS_DIAGNOSIS_HIST is only needed for cancer diagnosis when editing a past staging diagnosis  -->
    *              <DIAGNOSIS ID="" FLG_TYPE="" /> <!-- This information is available just when creating a new diagnosis -->
    *              <EPIS_DIAGNOSIS ID_EPIS_DIAGNOSIS="" ID_EPIS_DIAGNOSIS_HIST="" /> <!-- This information is available just when editing a existing diagnosis -->
    *              <DS_COMPONENT INTERNAL_NAME="" FLG_COMPONENT_TYPE="" /> <!-- Used to get information of form sections, etc...; NAME = I_COMPONENT_NAME; TYPE = I_COMPONENT_TYPE -->
    *              <TOPOGRAPHY ID="" /> <!-- Selected user option -->
    *              <MORPHOLOGY HISTOLOGY="" BEHAVIOR="" GRADE="" />  <!-- Selected user option -->
    *              <TNM T="" N="" M="" />  <!-- Selected user option -->
    *              <STAGING_BASIS ID="" />  <!-- Selected user option -->
    *              <BASIS_DIAG ID="" /> <!-- Selected user option -->
    *              <DS_COMPONENTS> 
    *                  <!-- Used to get information of MS, MM, FR fields that depend on user selection -->
    *                  <!-- Set of fields whose values we want to get -->
    *                  <DS_COMPONENT ID_DS_CMPT_MKT_REL=""  ID_DS_COMPONENT_PARENT="" ID_DS_COMPONENT="" COMPONENT_DESC="" INTERNAL_NAME="" FLG_COMPONENT_TYPE="" FLG_DATA_TYPE="" SLG_INTERNAL_NAME="" RANK="" />
    *              </DS_COMPONENTS>
    *          </PARAMETERS>
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   17-01-2012
    */
    FUNCTION get_section_data
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_params       IN CLOB,
        o_section      OUT pk_types.cursor_type,
        o_def_events   OUT pk_types.cursor_type,
        o_events       OUT pk_types.cursor_type,
        o_items_values OUT pk_types.cursor_type,
        o_data_val     OUT CLOB,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get dynamic screen sections and events list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_params                    Group of parameters
    * @param   o_stage_info                Stage information
    * @param   o_error                     Error information
    *
    * @example i_params                    Example of the XML passed in this variable
    *
    * <PARAMETERS>
    *   <STAGING STAGING_BASIS="" TNM_T="" CODE_STAGE_T="" TNM_N="" CODE_STAGE_N="" TNM_M="" CODE_STAGE_M="">
    *     <PROG_FACTORS>
    *       <PROG_FACTOR ID_LABEL="" ID_VALUE="" />
    *     </PROG_FACTORS>
    *   </STAGING>
    * </PARAMETERS>
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   17-01-2012
    */
    FUNCTION get_calculate_fields_values
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_params     IN CLOB,
        o_stage_info OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the resulting ICDO diagnosis description to be placed in the form
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_params                    Group of parameters
    * @param   o_diag_icdo                 Diagnosis description
    * @param   o_error                     Error information
    *
    * @example i_params                    Example of the XML passed in this variable
    *
    * <PARAMETERS BEHAVIOR="" HISTOLOGY="" TOPOGRAPHY="" />
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6.2.1
    * @since   28-03-2012
    */
    FUNCTION get_calculate_diag_icdo
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_params    IN CLOB,
        o_diag_icdo OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Encapsulates the logic of saving (create/update/cancel) a diagnosis
    * (CALLED BY: FLASH)
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_params                XML with all input parameters
    * @param   o_params                XML with all output parameters
    * @param   o_error                 Error information
    *
    * @example i_params                Example of the possible XML passed in this variable
    *
    * <EPIS_DIAGNOSES ID_PATIENT="" ID_EPISODE="" PROF_CAT_TYPE="" FLG_TYPE="" FLG_EDIT_MODE="" ID_CDR_CALL="">
    *   <!-- 
    *   FLG_TYPE: P - Working diag; D - Final diag
    *   FLG_EDIT_MODE: Flag to diferentiate which fields are being updated
    *       S - Diagnosis Status edit
    *       T - Diagnosis Type edit
    *       N - Diagnosis screen edition (multiple values editable)
    *   --> 
    *   <EPIS_DIAGNOSIS ID_EPIS_DIAGNOSIS="" ID_EPIS_DIAGNOSIS_HIST=""  FLG_TRANSF_FINAL="" ID_CANCEL_REASON="" CANCEL_NOTES="" FLG_CANCEL_DIFF_DIAG="" >
    *     <!-- 
    *     ID_EPIS_DIAGNOSIS OR ID_EPIS_DIAGNOSIS_HIST mandatory when editing
    *     ID_EPIS_DIAGNOSIS is needed when editing the current episode diagnosis, in the case of cancer diagnosis also means editing the current staging diagnosis
    *     ID_EPIS_DIAGNOSIS_HIST is needed for cancer diagnosis when editing a past staging diagnosis
    *     --> 
    *     <!-- 
    *        In case of association only ID is needed for diagnosis
    *     --> 
    *     
    *     <DIAGNOSIS ID="" ID_ALERT_DIAG="" DESC_DIAGNOSIS="" FLG_FINAL_TYPE="" FLG_STATUS="" FLG_ADD_PROBLEM="" NOTES="" >
    *       <CHARACTERIZATION DT_INIT_DIAG="" BASIS_DIAG_MS="" BASIS_DIAG_SPEC= "" NUM_PRIM_TUMORS_MS_YN="" NUM_PRIM_TUMORS_NUM="" RECURRENCE="" />
    *       <!-- 
    *       DESC_DIAGNOSIS only available when creating a new diagnosis
    *       ID_ALERT_DIAG only necessary when creating
    *       -->
    *       <TUMORS>
    *         <TUMOR NUM="" TOPOGRAPHY="" LATERALITY="" HISTOLOGY="" BEHAVIOR="" HISTOLOGIC_GRADE="" OTHER_GRADING_SYSTEM=""
    *              PRIMARY_TUMOR_SIZE_UNKNOWN="" PRIMARY_TUMOR_SIZE_NUMERIC="" PRIMARY_TUMOR_SIZE_DESCRIPTIVE="" ADDITIONAL_PATH_INFO="" />
    *       </TUMORS>
    *       <STAGING STAGING_BASIS="" TNM_T="" TNM_N="" TNM_M="" METASTATIC_SITES="" RESIDUAL_TUMOR="" SURGICAL_MARGINS="" LYMPH_VASCULAR_INVASION="" OTHER_STAGING_SYSTEM="">
    *         <PROG_FACTORS>
    *           <PROG_FACTOR ID_LABEL="" ID_VALUE="" FT=""  />
    *         </PROG_FACTORS>
    *       </STAGING>
    *     </DIAGNOSIS>
    *     <!--
    *     FLG_CANCEL_DIFF_DIAG: Flag that indicates if differencial diagnoses should also be cancelled (This flag is only necessary when cancelling a final diagnosis)
    *     -->
    *   </EPIS_DIAGNOSIS>
    *   <GENERAL_NOTES ID="" VALUE="" ID_CANCEL_REASON="" />
    *   <!--
    *   ID: is equal to ID_EPIS_DIAGNOSIS_NOTES, this is only used when editing the general note
    *   ID_CANCEL_REASON: Only mandatory when cancelling the general notes
    *   -->
    * 
    * </EPIS_DIAGNOSES>
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author  Sergio Dias
    * @version 1.0
    * @since   14/Fev/2012
    */
    FUNCTION set_epis_diagnosis
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_params      IN CLOB,
        i_audit_trail IN VARCHAR2, --ATTENTION: this field is here only because of audit trail
        o_params      OUT CLOB,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that gives the viewer staging info of a specific diagnosis record
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_episode                episode ID
    * @param i_epis_diag              episode diagnosis ID
    * @param o_epis_diagnosis         diagnosis data
    * @param o_error                  error message
    *
    * @return                         true or false
    *
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          2012/02/27
    **********************************************************************************************/
    FUNCTION get_epis_diagnosis_viewer
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_diag      IN epis_diagnosis.id_epis_diagnosis%TYPE,
        o_epis_diagnosis OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get the diagnosis info to be placed in the viewer grid
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_patient                patient id
    * @param i_episode                episode id
    * @param i_epis_diag              diagnosis episode id
    * @param o_diag_staging           diangosis staging info
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        2.6.2.1
    * @since                          29-Mar-2012
    **********************************************************************************************/
    FUNCTION get_diag_viewer_info
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_epis_diag    IN epis_diagnosis.id_epis_diagnosis%TYPE,
        o_diag_staging OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that gives the active detail staging info of a specific diagnosis record
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_episode                episode ID
    * @param i_epis_diag              episode diagnosis ID
    * @param o_epis_diagnosis         diagnosis data
    * @param o_error                  error message
    *
    * @return                         true or false
    *
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          2012/02/27
    **********************************************************************************************/
    FUNCTION get_epis_diag_active_det
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_diag      IN epis_diagnosis.id_epis_diagnosis%TYPE,
        o_epis_diagnosis OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that gives the history detail of a specific diagnosis record
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_episode                episode ID
    * @param i_epis_diag              episode diagnosis ID
    * @param o_epis_diagnosis         diagnosis data
    * @param o_error                  error message
    *
    * @return                         true or false
    *
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          2012/02/27
    **********************************************************************************************/
    FUNCTION get_epis_diag_hist_det
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_diag      IN epis_diagnosis.id_epis_diagnosis%TYPE,
        o_epis_diagnosis OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get the options for the actions button in the diagnosis grid 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_epis_diagnosis         episode diagnosis ID
    * @param o_diag_actions           actions list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          27-02-2012
    **********************************************************************************************/
    FUNCTION get_diag_actions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE,
        o_diag_actions   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get the notes registered in the diagnosis area 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_episode                episode ID
    * @param o_diag_notes             diagnosis notes list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          28-02-2012
    **********************************************************************************************/
    FUNCTION get_epis_diag_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_diag_notes OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get the notes registered in the diagnosis area 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_episode                episode ID
    * @param o_diag_notes             diagnosis notes list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          28-02-2012
    **********************************************************************************************/
    FUNCTION get_epis_diag_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_flg_type   IN epis_diagnosis.flg_type%TYPE,
        o_diag_notes OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Sets the diagnosis notes  
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_episode                episode ID
    * @param i_epis_diag_notes        previous diagnosis notes ID (if it is an edition)
    * @param i_notes                  registered notes
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          28-02-2012
    **********************************************************************************************/
    FUNCTION set_epis_diag_notes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_diag_notes IN epis_diagnosis_notes.id_epis_diagnosis_notes%TYPE,
        i_notes           IN epis_diagnosis_notes.notes%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancel the diagnosis notes  
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_epis_diag_notes        diagnosis notes ID to be cancelled
    * @param i_cancel_reason          cancel reason
    * @param i_notes                  cancel notes
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          28-02-2012
    **********************************************************************************************/
    FUNCTION cancel_diag_notes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis_diag_notes IN epis_diagnosis_notes.id_epis_diagnosis_notes%TYPE,
        i_cancel_reason   IN cancel_reason.id_cancel_reason%TYPE,
        i_notes           IN epis_diagnosis_notes.notes%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * List all diagnosis registered in an episode
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_episode                Episode id
    * @param i_flg_type               Diagnosis type: P - differential, D - final
    * @param o_list                   Diagnoses list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         José Silva
    * @version                        1.0
    * @since                          2012/02/29
    **********************************************************************************************/
    FUNCTION get_epis_diagnosis_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN epis_diagnosis.flg_type%TYPE,
        o_list     OUT pk_edis_types.diagnosis_cur,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the options available in the diagnosis filter
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @param i_episode                Episode ID
    * @param i_flg_type               Diagnosis type: P - differential, D - final
    * @param o_options                Filter options
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        2.6.2.1   
    * @since                          2012/03/22
    **********************************************************************************************/
    FUNCTION get_diag_filter_options
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN VARCHAR2,
        o_options  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get diagnoses types
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_tbl_diagnosis          Table of diagnosis id's
    * @param o_diag_type              For each received diagnosis tells the diagnosis type and ds leaf path
    * @param o_error                  Error message
    *
    * @return                         true or false para sucesso ou erro
    *                        
    * @author                         Alexandre Santos
    * @version                        2.6.3
    * @since                          22-08-2013
    **********************************************************************************************/
    FUNCTION get_diag_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_tbl_diagnosis IN table_number,
        o_diag_type     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the patient age on the given date
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_when                      Date on which you want to know the patient's age
    * @param   o_pat_age                   Patient age on the given date
    * @param   o_error                     Error information
    *
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.2.1
    * @since   28-03-2012
    */
    FUNCTION get_pat_age
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_when    IN VARCHAR2,
        o_pat_age OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check if any of the selected diagnoses were registered in a past episode
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_params                    Group of parameters
    * @param   o_title                     Confirmation title
    * @param   o_msg                       Confirmation message
    * @param   o_diags                     Diagnoses info
    * @param   o_error                     Error information
    *
    * @example i_params                    Example of the XML passed in this variable
    *
    * <PARAMETERS ID_PATIENT="" ID_EPISODE="">
    *   <DIAGNOSIS ID_DIAGNOSIS="" ID_ALERT_DIAGNOSIS=""/>
    * </PARAMETERS>
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   26-06-2012
    */
    FUNCTION check_diag_already_reg
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_params IN CLOB,
        o_title  OUT VARCHAR2,
        o_msg    OUT VARCHAR2,
        o_diags  OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get description associated to the given epis_diagnosis
    *
    * @param   i_lang               Language identifier
    * @param   i_id_epis_diagnosis  Epis diagnosis identifier
    *
    * @return  BOOLEAN for success. 
    *
    * @author  Sofia Mendes
    * @version v2.6.2
    * @since   25-Sep-2012
    */
    FUNCTION get_diagnosis_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE,
        o_diag              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get diagnosis path based on its hierarchy
    *
    * @param   i_lang          Language ID
    * @param   i_prof          Professional data
    * @param   i_diagnosis     Diagnosis ID
    * @param   o_path          Diagnosis path cursor
    * @param   o_error         Error information
    *
    * @return  TRUE/FALSE
    *
    * @author  Sergio Dias
    * @version v2.6.3.9.1
    * @since   Jan-10-2014
    */
    FUNCTION get_diagnosis_path
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_diagnosis IN diagnosis.id_diagnosis%TYPE,
        o_path      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks if the user must be warned about the current diagnosis creation/edition
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_episode                episode ID
    * @param i_epis_diagnosis         diagnosis record associated to the episode (when editing a diagnosis)
    * @param i_flg_final_type         diagnosis type: P - primary, S - secondary
    * @param o_flg_show               The warning screen should appear? Y - yes, N - No
    * @param o_msg                    Warning message
    * @param o_error                  Error message
    *
    * @return                         true or false para sucesso ou erro
    *
    * @author                         José Silva
    * @version                        1.0   
    * @since                          2009/09/07
    **********************************************************************************************/
    FUNCTION check_primary_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_flg_final_type IN table_varchar,
        i_diagnosis      IN table_number,
        o_flg_show       OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks if the user must be warned about the current diagnosis creation/edition
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_episode                episode ID
    * @param i_epis_diagnosis         diagnosis record associated to the episode (when editing a diagnosis)
    * @param i_flg_final_type         diagnosis type: P - primary, S - secondary
    * @param i_sub_analysis           sub analysis id
    * @param i_anatomical_area        anatomical area id
    * @param i_anatomical_side        anatomical side id
    * @param o_flg_show               The warning screen should appear? Y - yes, N - No
    * @param o_msg                    Warning message
    * @param o_error                  Error message
    *
    * @return                         true or false para sucesso ou erro
    *
    * @author                         José Silva
    * @version                        1.0   
    * @since                          2009/09/07
    **********************************************************************************************/
    FUNCTION check_prim_diag_and_dup
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_diagnosis  IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_flg_final_type  IN table_varchar,
        i_diagnosis       IN table_number,
        i_sub_analysis    IN table_number,
        i_anatomical_area IN table_number,
        i_anatomical_side IN table_number,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    **********************************************************************************************/
    FUNCTION check_prim_diag_and_dup
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_diagnosis  IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_flg_final_type  IN table_varchar,
        i_diagnosis       IN table_number,
        i_sub_analysis    IN table_number,
        i_anatomical_area IN table_number,
        i_anatomical_side IN table_number,
        i_rank            IN table_number,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_diagnoses_types
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_id_diagnoses       IN table_number,
        i_id_alert_diagnoses IN table_number,
        o_areas_domain       OUT pk_types.cursor_type,
        o_diagnoses_types    OUT table_table_varchar,
        o_diagnoses_warning  OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_epis_diag_stat_new_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_type   IN epis_diagnosis.flg_type%TYPE,
        i_id_episode IN epis_diagnosis.id_episode%TYPE,
        o_status     OUT pk_edis_types.cursor_status,
        o_assoc_prob OUT pk_edis_types.cursor_assoc_prob,
        o_max_rank   OUT epis_diagnosis.rank%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    **********************************************************************************************/
    FUNCTION check_rank_and_complications
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_flg_type               IN epis_diagnosis.flg_type%TYPE, -- D: discharge(final) / P: differencial
        i_diagnosis_list         IN table_number,
        i_desc_diagnosis_list    IN table_varchar,
        i_complication_list      IN table_number,
        i_desc_complication_list IN table_varchar,
        i_rank_list              IN table_number,
        o_flg_show               OUT VARCHAR2,
        o_msg                    OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    **********************************************************************************************/

    FUNCTION check_dup_icd_diag
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_type           IN epis_diagnosis.flg_type%TYPE,
        i_flg_transf_final   IN VARCHAR2,
        i_id_diagnosis_list  IN table_number,
        i_id_alert_diag_list IN table_number,
        i_add_to_problems    IN table_varchar,
        o_flg_show           OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_mandatory_sections
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_diagnosis       IN table_number,
        i_id_alert_diagnosis IN table_number,
        i_desc_diagnosis     IN table_varchar,
        i_flg_type           IN table_varchar,
        o_mandatory_sections OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

END pk_diagnosis_ux;
/
