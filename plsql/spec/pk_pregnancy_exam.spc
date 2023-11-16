/*-- Last Change Revision: $Rev: 2055401 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2023-02-22 09:43:55 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE pk_pregnancy_exam AS

    FUNCTION check_exam_pregn_conditions
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_exam            IN table_number,
        i_exam_req_det    IN table_number, /*exam_req_det.id_exam_req_det%TYPE,*/
        o_flg_female_exam OUT VARCHAR2,
        o_pat_pregnancy   OUT pk_types.cursor_type,
        o_pat_exams       OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_exam_pregn
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_exam_req        IN table_number,
        o_flg_female_exam OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_type_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_exam_type IN exam_type.flg_type%TYPE,
        o_exam      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_cab_exam_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN exam_req.id_episode%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_exam_type     IN exam.flg_type%TYPE,
        i_flg_type      IN exam_type.flg_type%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_exam          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_new_exam_res_fetus_biom
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_pat_pregn_fetus_biom IN pat_pregn_fetus_biom.id_pat_pregn_fetus_biom%TYPE,
        i_id_exam_res_pregn_fetus IN exam_res_pregn_fetus.id_exam_res_pregn_fetus%TYPE,
        o_id_exam_res_fetus_biom  OUT exam_res_fetus_biom.id_exam_res_fetus_biom%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_type_vs
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_exam_type  IN exam_type.flg_type%TYPE,
        o_vital_sign OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_fetus_vs
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_exam_result  IN exam_result.id_exam_result%TYPE,
        i_fetus_number IN pat_pregn_fetus.fetus_number%TYPE,
        o_vital_sign   OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_exam_pregn_general
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_exam_req_det   IN exam_req_det.id_exam_req_det%TYPE,
        i_weeks          IN exam_result_pregnancy.weeks_pregnancy%TYPE,
        i_flg_criteria   IN exam_result_pregnancy.flg_weeks_criteria%TYPE,
        i_flg_multiple   IN pat_pregnancy.flg_multiple%TYPE,
        i_fetus_number   IN pat_pregnancy.n_children%TYPE,
        o_id_exam_result OUT exam_result.id_exam_result%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_exam_pregn_info
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_id_exam_req_det  IN exam_req_det.id_exam_req_det%TYPE,
        i_id_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_id_pat_pregnancy OUT pat_pregnancy.id_pat_pregnancy%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_exam_pregn_info
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_id_exam_req_det  IN table_number,
        i_id_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_id_pat_pregnancy OUT pat_pregnancy.id_pat_pregnancy%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Replicates the ultrasound pregnancy information in a recurrence plan
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_new_exam_req_det       New exam request ID
    * @param i_old_exam_req_det       Old exam request ID (that originated the recurrence plan)
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        2.6.1.1
    * @since                          2011/06/27
    **********************************************************************************************/
    FUNCTION create_exam_pregn_recurr
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_new_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_old_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_fetus_doc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_doc_template      IN doc_template.id_doc_template%TYPE,
        o_vital_sign        OUT pk_types.cursor_type,
        o_component         OUT pk_types.cursor_type,
        o_element           OUT pk_types.cursor_type,
        o_elemnt_status     OUT pk_types.cursor_type,
        o_elemnt_action     OUT pk_types.cursor_type,
        o_element_exclusive OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_fetus_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_exam_result  IN exam_result.id_exam_result%TYPE,
        i_fetus_number IN pat_pregn_fetus.fetus_number%TYPE,
        o_vital_sign   OUT pk_types.cursor_type,
        o_filled_vs    OUT pk_types.cursor_type,
        o_last_update  OUT pk_types.cursor_type,
        o_fetus_gender OUT pk_types.cursor_type,
        o_epis_doc     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_screen_name
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_exam        IN exam.id_exam%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        o_screen_name OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_doc_template
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_exam      IN exam.id_exam%TYPE,
        i_trimester IN NUMBER,
        --o_doc_template OUT doc_template.id_doc_template%TYPE,
        o_doc_template OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_uts_exam_detail_main
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_exam_result IN exam_result.id_exam_result%TYPE,
        o_detail         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_ultrasound_summ_page
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        o_general      OUT pk_types.cursor_type,
        o_det_fetus    OUT pk_types.cursor_type,
        o_vital_sign   OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_ultrasound_summ_page_rep
    (
        i_lang         IN language.id_language%TYPE,
        i_prof_id      IN professional.id_professional%TYPE,
        i_prof_inst    IN institution.id_institution%TYPE,
        i_prof_sw      IN software.id_software%TYPE,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        o_general      OUT pk_types.cursor_type,
        o_det_fetus    OUT pk_types.cursor_type,
        o_vital_sign   OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_new_res_fetus_biom_img
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_id_exam_res_fetus_biom     IN exam_res_fetus_biom.id_exam_res_fetus_biom%TYPE,
        i_id_doc_external            IN doc_external.id_doc_external%TYPE,
        o_id_exam_res_fetus_biom_img OUT exam_res_fetus_biom_img.id_exam_res_fetus_biom_img%TYPE,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION set_new_result_no_pregnancy
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_prof_cat_type        IN category.flg_type%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_exam_req_det      IN exam_req_det.id_exam_req_det%TYPE,
        i_notes                IN VARCHAR2,
        i_id_pat_pregnancy     IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_document_area        IN doc_area.id_doc_area%TYPE,
        i_epis_complaint       IN epis_complaint.id_epis_complaint%TYPE,
        i_id_sys_documentation IN table_number,
        i_id_sys_element       IN table_number,
        i_id_sys_element_crit  IN table_number,
        i_value                IN table_varchar,
        i_doc_notes            IN epis_documentation_det.notes%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
    * Encapsulates the logic of saving a pregnancy exam request
    *
    * @param   i_lang             Professional preferred language
    * @param   i_prof             Professional identification and its context (institution and software)
    * @param   i_patient          Patient id
    * @param   i_params           XML with all input parameters
    * @param   o_exam_req         Exams order id
    * @param   o_exam_req_det     Exams order details id 
    * @param   o_pat_pregnancy    Pat pregnancy id 
    * @param   o_exam_result      Exams result id 
    * @param   o_pat_pregn_fetus  Pat pregnancy fetus id 
    * @param   o_error            Error information
    *
    * @example i_params           Example of the possible XML passed in this variable
    * <PREGNANCY_EXAM_ALL>
    *   <ID_EPISODE></ID_EPISODE>
    *   <PROF_CAT_TYPE></PROF_CAT_TYPE>
    *   <ID_PAT_PREGNANCY></ID_PAT_PREGNANCY>
    *   <!-- EXAM_TAGS - BEGIN -->
    *   <!-- 
    *     1 - At least one of the following tags must have a value 
    *     2 - If (ID_EXAM_REQ_DET is NULL) then a call is made to CREATE_EXAM_WITH_RESULT function and then to CREATE_EXAM_PREGN_INFO function 
    *     3 - It's always called the functions SET_EXAM_PREGN_GENERAL and SET_RESULT_FETUS 
    *   -->
    *   <ID_EXAM></ID_EXAM>
    *   <ID_EXAM_REQ_DET></ID_EXAM_REQ_DET>
    *   <!-- EXAM_TAGS - END -->
    *   <ID_DOC_AREA></ID_DOC_AREA>
    *   <WEEKS></WEEKS>
    *   <FLG_CRITERIA></FLG_CRITERIA>
    *   <FLG_MULTIPLE></FLG_MULTIPLE>
    *   <!-- Fetus sequence -->
    *   <FETAL>
    *       <FETUS ID="" FLG_GENDER=""> <!-- Fetus ID = 1..N where 1 is the first fetus and N represents the N fetus -->
    *       <!-- VS sequence -->
    *       <VITAL_SIGNS>
    *            <VITAL_SIGN ID_VITAL_SIGN="" VALUE="" IMAGE="" />
    *       </VITAL_SIGNS>
    *       <!-- DOCs sequence -->
    *       <DOCS>
    *            <DOC ID_DOCUMENTATION="" ID_DOC_ELEMENT="" ID_DOC_ELEMENT_CRIT="" VALUE="" />
    *       </DOCS>
    *       </FETUS>
    *   </FETAL>
    * </PREGNANCY_EXAM_ALL>
    * <EXAM_ORDER>
    *   <ID_EPISODE></ID_EPISODE>
    *   <FLG_TEST></FLG_TEST>
    *   <!-- Exams sequence -->
    *   <EXAMS>
    *     <EXAM ID="" FLG_TYPE="" CODIFICATION="" FLG_TIME="" DT_BEGIN="" PRIORITY="" EXEC_ROOM="" EXEC_INST="" CLINICAL_PURPOSE="">
    *       <NOTES></NOTES>
    *       <TECH_NOTES></TECH_NOTES>
    *       <PAT_NOTES></PAT_NOTES>
    *       <ORDER ID_PROF="" DATE="" TYPE="" />
    *       <!-- Diagnoses sequence -->
    *       <DIAGNOSES>
    *         <DIAGNOSIS ID_DIAGNOSIS="" DESC="" />
    *       </DIAGNOSES>
    *       <!-- Clinical questions sequence -->
    *       <CLINICAL_QUESTIONS>
    *         <CLINICAL_QUESTION ID="" RESPONSE="" NOTES="" />
    *       </CLINICAL_QUESTIONS>
    *     </EXAM>
    *   </EXAMS>
    * </EXAM_ORDER>
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   27-05-2010
    */
    FUNCTION set_pregnancy_exam_all
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_params             IN CLOB,
        o_exam_req           OUT exam_req.id_exam_req%TYPE,
        o_exam_req_det       OUT exam_req_det.id_exam_req_det%TYPE,
        o_pat_pregnancy      OUT pat_pregnancy.id_pat_pregnancy%TYPE,
        o_exam_result        OUT exam_result.id_exam_result%TYPE,
        o_id_pat_pregn_fetus OUT pat_pregn_fetus.id_pat_pregn_fetus%TYPE,
        o_flg_show           OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_msg_req            OUT VARCHAR2,
        o_button             OUT VARCHAR2,
        o_exam_req_array     OUT NOCOPY table_number,
        o_exam_req_det_array OUT NOCOPY table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Encapsulates the logic of saving a pregnancy exam request
    *
    * @param   i_lang             Professional preferred language
    * @param   i_prof             Professional identification and its context (institution and software)
    * @param   i_exam_req_det     Exam req det id
    *
    * @return  Table of t_preg_result
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   27-05-2010
    */
    FUNCTION tf_get_pregn_result_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_result.id_exam_req_det%TYPE
    ) RETURN t_col_preg_result;

    FUNCTION get_pregnancy_confirm_form_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION tf_get_pregn_associated_opt
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_female_exam IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_core_domain;

    FUNCTION set_pat_pregnancy
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        i_tbl_ds_internal_name IN table_varchar,
        i_tbl_real_val         IN table_varchar,
        i_cdr_call             IN cdr_event.id_cdr_call%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**######################################################
      GLOBAIS
    ######################################################**/
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    g_error         VARCHAR2(2000);
    g_exception EXCEPTION;

    g_found    BOOLEAN;
    g_notfound BOOLEAN;

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);

    g_exam_mov_pat exam_dep_clin_serv.flg_mov_pat%TYPE;

    g_flg_time_epis exam_req.flg_time%TYPE;
    g_flg_time_next exam_req.flg_time%TYPE;
    g_flg_time_betw exam_req.flg_time%TYPE;
    g_flg_time_resu exam_req.flg_time%TYPE;

    g_exam_det_tosched    exam_req_det.flg_status%TYPE;
    g_exam_det_sched      exam_req_det.flg_status%TYPE;
    g_exam_det_efectiv    exam_req_det.flg_status%TYPE;
    g_exam_det_req        exam_req_det.flg_status%TYPE;
    g_exam_det_result     exam_req_det.flg_status%TYPE;
    g_exam_det_canc       exam_req_det.flg_status%TYPE;
    g_exam_det_read       exam_req_det.flg_status%TYPE;
    g_exam_det_pend       exam_req_det.flg_status%TYPE;
    g_exam_det_exec       exam_req_det.flg_status%TYPE;
    g_exam_det_transp     exam_req_det.flg_status%TYPE;
    g_exam_det_end_transp exam_req_det.flg_status%TYPE;

    g_exam_req_det_status sys_domain.code_domain%TYPE;

    g_inp_software NUMBER;

    g_epis_type_outp epis_type.id_epis_type%TYPE := 1;
    g_epis_type_edis epis_type.id_epis_type%TYPE := 2;
    g_epis_type_oris epis_type.id_epis_type%TYPE := 4;
    g_epis_type_inp  epis_type.id_epis_type%TYPE := 5;
    g_epis_type_obs  epis_type.id_epis_type%TYPE := 6;
    g_epis_type_sap  epis_type.id_epis_type%TYPE := 9;
    g_epis_type_pp   epis_type.id_epis_type%TYPE := 11;

    g_exam_tosched exam_req.flg_status%TYPE;
    g_exam_sched   exam_req.flg_status%TYPE;
    g_exam_efectiv exam_req.flg_status%TYPE;
    g_exam_req     exam_req.flg_status%TYPE;
    g_exam_exec    exam_req.flg_status%TYPE;
    g_exam_canc    exam_req.flg_status%TYPE;
    g_exam_pend    exam_req.flg_status%TYPE;
    g_exam_res     exam_req.flg_status%TYPE;
    g_exam_part    exam_req.flg_status%TYPE;

    g_mov_status_finish movement.flg_status%TYPE;
    g_mov_status_interr movement.flg_status%TYPE;
    g_mov_status_cancel movement.flg_status%TYPE;
    g_mov_status_pend   movement.flg_status%TYPE;
    g_mov_status_req    movement.flg_status%TYPE;

    g_cat_type_doc   category.flg_type%TYPE;
    g_cat_type_tec   category.flg_type%TYPE;
    g_cat_type_nurse category.flg_type%TYPE;

    g_exam_available exam.flg_available%TYPE;
    g_exam_execute   exam_dep_clin_serv.flg_type%TYPE;
    g_exam_freq      exam_dep_clin_serv.flg_type%TYPE;
    g_exam_can_req   exam_dep_clin_serv.flg_type%TYPE;
    g_exam_conv      exam_dep_clin_serv.flg_type%TYPE;

    g_mov_pat         exam_dep_clin_serv.flg_mov_pat%TYPE;
    g_cat_doctor      category.flg_type%TYPE;
    g_result_type_tec exam_result.flg_type%TYPE;

    g_exam_type     VARCHAR2(1);
    g_exam_type_img exam.flg_type%TYPE;

    g_yes CONSTANT VARCHAR2(1) := 'Y';
    g_no  CONSTANT VARCHAR2(1) := 'N';
    g_epis_active episode.flg_status%TYPE;

    g_domain_flg_time sys_domain.code_domain%TYPE;
    g_epis_type       episode.id_epis_type%TYPE;
    g_selected        VARCHAR2(1);

    g_flg_available VARCHAR2(1);

    g_exam_ultrasound      exam_type.flg_type%TYPE;
    g_flg_pregnancy_active pat_pregnancy.flg_status%TYPE;
    --

    g_doc_active epis_documentation.flg_status%TYPE;
    g_doc_area_exam CONSTANT doc_area.id_doc_area%TYPE := 1083;

    g_edcs_flg_type_p     exam_dep_clin_serv.flg_type%TYPE;
    g_ext_doc_flg_state_f external_doc.flg_state%TYPE := 'F';

    -- 13-12-2007 CMF
    g_exam_type_req ti_log.flg_type%TYPE := 'ER';
    g_exam_type_det ti_log.flg_type%TYPE := 'ED';

    g_exam_session CONSTANT notes_config.notes_code%TYPE := 'IMG';
    g_exr_session  CONSTANT notes_config.notes_code%TYPE := 'EXR';
    g_otr_session  CONSTANT notes_config.notes_code%TYPE := 'OTR';
    g_anr_session  CONSTANT notes_config.notes_code%TYPE := 'ANR';
    g_mec_session  CONSTANT notes_config.notes_code%TYPE := 'MEC';

    g_exam_req_read exam_req.flg_status%TYPE;
    g_exam_req_canc exam_req.flg_status%TYPE;

    g_edis_software VARCHAR2(1);

    g_flg_admin category.flg_type%TYPE;
    g_flg_tech  category.flg_type%TYPE;

    g_cosign_type_exam CONSTANT co_sign_task.flg_type%TYPE := 'E';
    g_type_other_exams CONSTANT exam.flg_type%TYPE := 'E';

END pk_pregnancy_exam;
/
