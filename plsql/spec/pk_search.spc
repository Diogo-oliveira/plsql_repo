/*-- Last Change Revision: $Rev: 2028965 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:00 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_search IS

    FUNCTION get_overlimit_message
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_flg_has_action IN VARCHAR2,
        i_limit          IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION noresult_handler
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_pck_name IN VARCHAR2,
        i_unitname IN VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION overlimit_handler
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_pck_name IN VARCHAR2,
        i_unitname IN VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION invalid_number_handler
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_pck_name IN VARCHAR2,
        i_unitname IN VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_criteria
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_active          IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_pat             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Diagnosis search using an input value
    *
    * @param i_lang                   language identifier
    * @param i_value                  search input
    * @param i_prof                   logged professional structure
    * @param i_patient                patient ID
    * @param o_flg_show               shows warning message: Y - yes, N - No
    * @param o_msg                    message text
    * @param o_msg_title              message title
    * @param o_button                 buttons to show: N-No, R-Read, C-Confirmed
    * @param o_diag                   search result
    * @param o_error                  error
    *
    * @return                         false, if errors occur, true otherwise
    *                        
    * @author                         CRS
    * @version                        1.0
    * @since                          2005/03/31
    *
    * @author                         José Silva
    * @version                        2.0 (LUCENE Text Index usage)
    * @since                          2009/10/28
    **********************************************************************************************/
    FUNCTION get_diag_criteria
    (
        i_lang      IN language.id_language%TYPE,
        i_value     IN VARCHAR2,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_diag      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_diag_criteria_death
    (
        i_lang      IN language.id_language%TYPE,
        i_value     IN VARCHAR2,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_section   IN VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_diag      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_diag_criteria2
    (
        i_lang      IN language.id_language%TYPE,
        i_value     IN VARCHAR2,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_diag      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_criteria_condition
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_criteria    IN criteria.id_criteria%TYPE,
        i_criteria_value IN VARCHAR2,
        o_crit_condition OUT criteria.crit_condition%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /*
    * Gets the query for patient search
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional id, institution and software    
    * @param   i_id_criteria     Id Criteria 
    * @param   i_criteria_value  Criteria value       
    * @param   o_from_condition  Condition in SQL FROM Clause
    * @param   o_error           Error message    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   27-10-2010
    */
    FUNCTION get_from_condition
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_criteria    IN criteria.id_criteria%TYPE,
        i_criteria_value IN VARCHAR2,
        o_from_condition OUT criteria.from_condition%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_criteria_active
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt_str          IN VARCHAR2,
        i_prof            IN profissional,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Efectuar pesquisa de doentes ACTIVOS, de acordo com os critérios seleccionados, para pessoal clínico (médicos e enfermeiros)
    *
    * @param i_lang                   the id language
    * @param i_id_sys_btn_crit        Lista de ID'S de critérios de pesquisa.             
    * @param i_crit_val               Lista de valores dos critérios de pesquisa
    * @param i_instit                 institution id
    * @param i_epis_type              episode type
    * @param i_dt                     Data a pesquisar. Se for null assume a data de sistema
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_cat_type          professional category   
    * @param o_flg_show                
    * @param o_msg    
    * @param o_msg_title
    * @param o_button   
    * @param o_pat                    array with patient active
    * @param o_mess_no_result         Mensagem quando a pesquisa não devolver resultados  
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/06/05
    *
    * @author                         Sérgio Santos (Restructure)
    * @version                        1.0 
    * @since                          2009/01/27
    **********************************************************************************************/
    FUNCTION get_pat_criteria_active_clin
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt_str          IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_pat_criteria_active_clin
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_where IN VARCHAR2
    ) RETURN t_coll_patcritactiveclin_amb;

    FUNCTION get_pat_criteria_inactive
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt_str          IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Efectuar pesquisa de doentes INACTIVOS,de acordo com os critérios seleccionados, para pessoal clínico (médicos e enfermeiros)
    *
    * @param i_lang                   the id language
    * @param i_id_sys_btn_crit        Lista de ID'S de critérios de pesquisa.             
    * @param i_crit_val               Lista de valores dos critérios de pesquisa
    * @param i_instit                 institution id
    * @param i_epis_type              episode type
    * @param i_dt                     Data a pesquisar. Se for null assume a data de sistema
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_cat_type          professional category   
    * @param o_flg_show                
    * @param o_msg    
    * @param o_msg_title
    * @param o_button   
    * @param o_pat                    array with patient active
    * @param o_mess_no_result         Mensagem quando a pesquisa não devolver resultados  
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    *  @author RB 2005/04/22 
    *      ALTERAÇÃO: CRS 2006/07/20 EXCLUIR EPISÓDIOS CANCELADOS 
    *           ASM 2006/12/27 INCLUIR NÃO SÓ OS EPISÓDIOS COM ALTA ADMINISTRATIVA, MAS TAMBÉM OS COM ALTA MÉDICA E OS EPISÓDIOS 
    *                        QUE FORAM FECHADOS AUTOMATICAMENTE 
    *                                LIGAÇÃO À TABELA DOC_EXTERNAL PARA OS DOCUMENTOS, EM VEZ DA PAT_DOC 
    *
    * @author                         Sérgio Santos (Restructure)
    * @since                          2009/02/03
    **********************************************************************************************/
    FUNCTION get_pat_criteria_inactive_clin
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt_str          IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_pat_criteria_inactive_clin
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_where  IN VARCHAR2,
        i_dt_str IN VARCHAR2
    ) RETURN t_coll_patcritinactiveclin;

    FUNCTION get_pat_crit_sched_24h
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_prof            IN profissional,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt_str          IN VARCHAR2,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_crit_sched_today
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_prof            IN profissional,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt_str          IN VARCHAR2,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_crit_sched
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_crit_sched_clin
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_crit_mchoice_mkt_rel
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_internal_name IN ds_cmpt_mkt_rel.internal_name_child%TYPE
    ) RETURN t_tbl_core_domain;

    FUNCTION get_pat_crit_mchoice
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_criteria   IN criteria.id_criteria%TYPE,
        i_flg_mandatory IN sscr_crit.flg_mandatory%TYPE,
        o_mchoice       OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_search
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_prof            IN profissional,
        i_flg_search      IN VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_info            OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cod_diag_criteria
    (
        i_lang      IN language.id_language%TYPE,
        i_value     IN VARCHAR2,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_diag      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_inact_tech
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_prof            IN profissional,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_epis_inact_tech
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_where IN VARCHAR2,
        i_from  IN VARCHAR2
    ) RETURN t_coll_episinactech;

    FUNCTION get_all_patients
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_prof            IN profissional,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_where
    (
        i_criteria IN table_number,
        i_crit_val IN table_varchar,
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_where    OUT NOCOPY VARCHAR2
    ) RETURN BOOLEAN;

    FUNCTION get_from
    (
        i_criteria IN table_number,
        i_crit_val IN table_varchar,
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_from     OUT NOCOPY VARCHAR2,
        o_hint     OUT NOCOPY VARCHAR2
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Listar os agendamentos cancelados
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_sys_btn_crit        Lista de ID'S de critérios de pesquisa.             
    * @param i_crit_val               Lista de valores dos critérios de pesquisa
    * @param i_dt                     Data a pesquisar. Se for null assume a data de sistema
    * @param o_msg    
    * @param o_msg_title
    * @param o_button   
    * @param o_epis_inact             array with inactive episodes
    * @param o_mess_no_result         Mensagem quando a pesquisa não devolver resultados  
    * @param o_flg_show                
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Teresa Coutinho
    * @version                        1.0 
    * @since                          2008/12/23
    **********************************************************************************************/
    FUNCTION get_sched_canc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_dt              IN VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_sched_canc      OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Case management episodes search.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_crit_id                criteria identifier list
    * @param i_crit_val               criteria value list
    * @param i_type                   'A' for active episode search, 'I' for inactive episode search
    * @param o_epis                   results cursor
    * @param o_error                  error
    *
    * @return                         false, if errors occur, true otherwise
    *                        
    * @author                         Pedro Carneiro
    * @version                         2.5.0.7
    * @since                          2009/09/07
    **********************************************************************************************/
    FUNCTION get_cm_epis_criteria
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_crit_id  IN table_number,
        i_crit_val IN table_varchar,
        i_type     IN VARCHAR2,
        o_epis     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /***********************************************************************************************************
    * Esta função retorna uma string com as condições de pesquisa especificadas pelo utilizador.
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               ID do profissional
    * @param      i_id_sys_btn_crit
    * @param      i_crit_val
    *
    * @param      o_error              mensagem de erro
    *
    * @return     uma string com os critérios a adicionar à cláusula where ou NUll caso não tenham sido
    *              especificadas quaisquer critérios de selecção
    * @author     Orlando Antunes
    * @version    2.3.6.
    * @since
    ***********************************************************************************************************/
    FUNCTION get_read_search_criteria
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN VARCHAR2;

    /***********************************************************************************************************
    *  returns professional photo or name depending on the imput parameters
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               ID do profissional
    * @param      i_prof_id            Professional ID from which we want to return the information
    * @param      i_patient            Patient ID when we want the information from last appointment
    * @param      i_ret_type           Return type: photo or name
    *
    * @return     the professional photo or name depending on the imput parameters
    * @author     Pedro Teixeira
    * @version    2.5.0.7.5
    * @since
    ***********************************************************************************************************/
    FUNCTION get_software_prof_photo
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_id  IN professional.id_professional%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_ret_type IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    * Get patient's last episode type.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    *
    * @return               patient's last episode type
    *
    * @author               Pedro Carneiro
    * @version               2.5.0.7.6
    * @since                2010/01/13
    */
    FUNCTION get_last_epis_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN pk_translation.t_desc_translation;

    /********************************************************************************************
    * Return a distint id_patient list of all patients associated with a given software.
    * Since there is not a direct way to associate patient with a software
    *    we use EPIS_TYPE_SOFT_INST to find which EPIS_TYPES are associated with the software.
    * This list is used to generate CDAs information so that it can be exported - ALERT-257677
    *
    * @param i_lang                           language info
    * @param i_prof                           professional info
    * @param o_pat                            Cursor with the requested list
    *
    * @author                                 Bruno Martins
    * @version                                2.6.4
    * @since                                  2014-05-08
    ********************************************************************************************/
    FUNCTION get_all_patients_from_software
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_pat   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_type_access
    (
        i_prof     IN profissional,
        i_grp_inst IN table_number
    ) RETURN table_number;

    /**********************************************************************************************
    * Returns canceled patients through a given criteria
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional id, institution and software    
    * @param   i_id_sys_btn_crit list of search criteria ids
    * @param   i_crit_val list of values for the criteria in  i_id_sys_btn_crit
    *
    * @author                    CRISTINA.OLIVEIRA
    * @version                   2.8.1.0
    * @since                     2019/12/11
    **********************************************************************************************/
    FUNCTION get_pat_criteria_cancelled
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        o_pat             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Initialize params for filters cancelled search  
    *
    * @param i_context_ids            array with context ids
    * @param i_context_keys           array with context keys
    * @param i_context_vals           array with context values
    * 
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                         CRISTINA.OLIVEIRA
    * @version                        2.8.1.0
    * @since                          2019/12/11
    **********************************************************************************************/
    PROCEDURE init_params_search_grids_canc
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    FUNCTION get_inactive_search_values
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
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_active_search_values
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
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_submit_values
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
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;
    ------------------------------------------------------------------------------------

    g_error        VARCHAR2(32000);
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(200);

    g_visit_active    visit.flg_status%TYPE;
    g_clin_rec_active clin_record.flg_status%TYPE;
    g_diag_available  diagnosis.flg_available%TYPE;
    g_diag_no_select  diagnosis.flg_select%TYPE;
    g_diag_other      diagnosis.flg_other%TYPE;

    g_commonmsg_all CONSTANT sys_message.code_message%TYPE := 'COMMON_M014';
    g_commonmsg_any CONSTANT sys_message.code_message%TYPE := 'COMMON_M059';

    g_multivalue_criteria  CONSTANT criteria.flg_type%TYPE := 'C';
    g_multichoice_criteria CONSTANT criteria.flg_type%TYPE := 'M';

    g_mandatory_true  CONSTANT sscr_crit.flg_mandatory%TYPE := 'Y';
    g_mandatory_false CONSTANT sscr_crit.flg_mandatory%TYPE := 'N';

    g_epis_active   episode.flg_status%TYPE;
    g_epis_inactive episode.flg_status%TYPE;

    g_found BOOLEAN;

    g_flg_doctor category.flg_type%TYPE;
    g_flg_nurse  category.flg_type%TYPE;
    g_flg_adm    category.flg_type%TYPE;
    g_flg_aux    category.flg_type%TYPE;
    g_flg_nutri  category.flg_type%TYPE := 'U';
    g_flg_tech   category.flg_type%TYPE := 'T';

    g_diag_type_icd  diagnosis.flg_type%TYPE;
    g_diag_type_icpc diagnosis.flg_type%TYPE;
    g_instit_type_cs institution.flg_type%TYPE;
    g_instit_type_hs institution.flg_type%TYPE;

    g_sched_efectiv   schedule_outp.flg_state%TYPE;
    g_sched_scheduled schedule_outp.flg_state%TYPE;

    g_sched_cancel schedule.flg_status%TYPE;

    g_exam_sched  VARCHAR2(1);
    g_exam_result VARCHAR2(1);

    g_exam_func  exam.flg_type%TYPE;
    g_exam_audio exam.flg_type%TYPE;
    g_exam_ortho exam.flg_type%TYPE;
    g_exam_image exam.flg_type%TYPE;
    g_exam_gastr exam.flg_type%TYPE;

    g_interv_fin interv_prescription.flg_status%TYPE;

    g_flg_time_n VARCHAR2(1);
    g_flg_time_b VARCHAR2(1);
    g_flg_time_e VARCHAR2(1);

    g_flg_canc    VARCHAR2(1);
    g_flg_intr    VARCHAR2(1);
    g_flg_fin     VARCHAR2(1);
    g_flg_read    VARCHAR2(1);
    g_flg_pending VARCHAR2(1);

    g_epis_type_rad    CONSTANT NUMBER := 13;
    g_epis_type_exm    CONSTANT NUMBER := 21;
    g_epis_type_lab    CONSTANT NUMBER := 12;
    g_epis_type_interv CONSTANT NUMBER := 24;

    g_epis_canc episode.flg_status%TYPE;

    g_doc_active doc_external.flg_status%TYPE;

    g_disch_type_doctor epis_info.flg_status%TYPE;
    g_disch_type_adm    epis_info.flg_status%TYPE;
    g_disch_type_alert  epis_info.flg_status%TYPE;

    g_discharge_status_active   discharge.flg_status%TYPE;
    g_domain_sch_outp_flg_sched sys_domain.code_domain%TYPE;

    g_selected VARCHAR2(1);
    g_yes      VARCHAR2(1);
    g_no       VARCHAR2(1);

    g_diag_show_code sys_config.value%TYPE;

    g_clob CLOB;

    g_task_analysis CONSTANT VARCHAR2(1) := 'A';
    g_task_exam     CONSTANT VARCHAR2(1) := 'E';
    g_task_harvest  CONSTANT VARCHAR2(1) := 'H';
    g_clin_active   CONSTANT VARCHAR2(1) := 'A';

    g_icon_ft          CONSTANT VARCHAR2(1) := 'F';
    g_icon_ft_transfer CONSTANT VARCHAR2(1) := 'T';
    g_ft_color         CONSTANT VARCHAR2(200) := '0xFFFFFF';
    g_ft_triage_white  CONSTANT VARCHAR2(200) := '0x787864';
    g_ft_status        CONSTANT VARCHAR2(1) := 'A';
    g_desc_grid        CONSTANT VARCHAR2(1) := 'G';

    g_flg_ehr           CONSTANT VARCHAR2(1) := 'E';
    g_sched_nurse_disch CONSTANT VARCHAR2(1) := 'P';
    g_date_mask         CONSTANT VARCHAR2(16) := 'YYYYMMDDHH24MISS';

    --- ambulatory software
    g_software_care             CONSTANT software.id_software%TYPE := 3;
    g_software_outpatient       CONSTANT software.id_software%TYPE := 1;
    g_software_private_practice CONSTANT software.id_software%TYPE := 12;
    g_software_nutri            CONSTANT software.id_software%TYPE := 43;

    g_exception      EXCEPTION;
    g_exception_user EXCEPTION;
    g_user_action_type CONSTANT VARCHAR2(1) := 'U';

    e_overlimit EXCEPTION;
    e_noresults EXCEPTION;
    --
    g_inst_grp_flg_rel_adt CONSTANT institution_group.flg_relation%TYPE := 'ADT';

    --Handoff responsabilities constants
    g_show_in_grid    CONSTANT VARCHAR2(1) := 'G';
    g_show_in_tooltip CONSTANT VARCHAR2(1) := 'T';

    g_zero               CONSTANT PLS_INTEGER := 0;
    g_one                CONSTANT PLS_INTEGER := 1;
    g_cf_pat_gender_abbr CONSTANT sys_config.id_sys_config%TYPE := 'PATIENT.GENDER.ABBR';
    g_pl                 CONSTANT VARCHAR2(50) := '''';

    --type of encounter constants
    g_appointment_type CONSTANT VARCHAR2(1) := 'A';

END pk_search;
/
