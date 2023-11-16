/*-- Last Change Revision: $Rev: 2028563 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:32 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_clinical_info IS
    /********************************************************************************************
    * Criar queixa / anamnese 
    *
    * @param i_lang                 id da lingua
    * @param i_episode              episode id
    * @param i_prof                 objecto com info do utilizador
    * @param i_desc                 descrição da queixa / anamnese 
    * @param i_flg_type             C - queixa ; A - anamnese
    * @param i_flg_type_mode        type of edition
    * @param i_id_epis_anamnesis    Episódio da queixa/historia 
    * @param i_id_diag              ID do diagnóstico associado ao texto + freq.seleccionado para registo da queixa / história 
    * @param i_flg_class            A - motivo administrativo de consulta (CARE: texto + freq. do ICPC2)
    * @param i_prof_cat_type        Tipo de categoria do profissional, tal como é retornada em PK_LOGIN.GET_PROF_PREF
    * @param o_id_epis_anamnesis    registo           
    * @param o_error                Error message
    *
    * @value i_flg_type_mode        {*} 'N'  New {*} 'E' Edit {*} 'A' Agree {*} 'U' Update from previous assessment {*} 'O' No changes
    * @return                       true or false on success or error
    * 
    * @author                       Claudia Silva
    * @version                      1.0
    * @since                        2005/03/04
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1   
    *                             2008/05/08
    *                             Added new edit options: Update from previous assessment; No changes; 
    ********************************************************************************************/
    FUNCTION set_epis_anamnesis
    (
        i_lang              IN language.id_language%TYPE,
        i_episode           IN epis_anamnesis.id_episode%TYPE,
        i_prof              IN profissional,
        i_desc              IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_flg_type          IN epis_anamnesis.flg_type%TYPE,
        i_flg_type_mode     IN VARCHAR2,
        i_id_epis_anamnesis IN epis_anamnesis.id_epis_anamnesis%TYPE,
        i_id_diag           IN epis_anamnesis.id_diagnosis%TYPE,
        i_flg_class         IN epis_anamnesis.flg_class%TYPE,
        i_prof_cat_type     IN category.flg_type%TYPE,
        o_id_epis_anamnesis OUT epis_anamnesis.id_epis_anamnesis%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_all_epis_anamnesis
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN epis_anamnesis.id_episode%TYPE,
        i_flg_type IN epis_anamnesis.flg_type%TYPE,
        i_prof     IN profissional,
        o_desc     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_last_id_epis_anamnesis
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN epis_anamnesis.id_episode%TYPE,
        i_flg_type IN epis_anamnesis.flg_type%TYPE,
        o_id_compl OUT epis_anamnesis.id_epis_anamnesis%TYPE,
        o_id_anamn OUT epis_anamnesis.id_epis_anamnesis%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
    * Obter queixas / anamneses do episódio 
    *
    * @param I_LANG - Língua registada como preferência do profissional 
    * @param I_EPISODE - ID do episódio actual 
    * @param  I_PROF - ID do profissional
    * @param  I_FLG_TYPE - C queixa, A - anamnese 
    * @param O_TEMP - último registo temporário
    * @param O_DEF - último registo definitivo registado antes da passagem de temporários para definitivos + 
    *                todos os registos definitivos registado após a passagem de temporários para definitivos
    * @param O_ERROR - erro 
    *  
    * @author CRS 2005/04/05, SS 2005/12/30, SS 2006/10/12 - mostrar sempre o último temporário qualquer seja o utilizador (independentemente de ser o autor do registo)
    */
    FUNCTION get_last_epis_anamnesis
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN epis_anamnesis.id_episode%TYPE,
        i_prof     IN profissional,
        i_flg_type IN epis_anamnesis.flg_type%TYPE,
        o_temp     OUT pk_types.cursor_type,
        o_def      OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Obter detalhe das queixas / anamneses do episódio 
    *
    * @param I_LANG - Língua registada como preferência do profissional 
    * @param I_EPISODE - ID do episódio actual 
    * @param I_PROF - ID do profissional
    * @param I_FLG_TYPE - C queixa, A - anamnese 
    * @param O_DET - último registo temporário  
    * @param  O_ERROR - erro 
    *  
    * @author SS
    * @since 2006/10/12 
    */
    FUNCTION get_epis_anamnesis_det
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN epis_anamnesis.id_episode%TYPE,
        i_prof     IN profissional,
        i_flg_type IN epis_anamnesis.flg_type%TYPE,
        o_det      OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Indica se o episódio tem registos de queixa ou anamneses em texto livre
    *
    * @param i_lang            id da lingua 
    * @param i_episode         id do episódio
    * @param i_prof            objecto do profissional
    * @param i_flg_type        informação que se quer saber: C para queixa e A para anamnese 
    * @param o_flg_data        flag com valores Y/N que indica se há ou não, respectivamente, os registos  
    * @param o_error           mensagem de erro
    *
    * @return                  true successo, false erro
    *  
    * @author                  João Eiras
    * @version                 1.0
    * @since                   2007/09/20 
    ********************************************************************************************/
    FUNCTION get_epis_anamnesis_exists
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN epis_anamnesis.id_episode%TYPE,
        i_prof     IN profissional,
        i_flg_type IN epis_anamnesis.flg_type%TYPE,
        o_flg_data OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Retorna informação relativa ao último registo de queixa ou anamneses neste episódio, em texto livre
    *
    * @param i_lang                id da lingua 
    * @param i_episode             id do episódio
    * @param i_prof                objecto do profissional
    * @param i_flg_type            informação que se quer saber: C para queixa e A para anamnese 
    * @param o_last_update         cursor con informação  
    * @param o_error               mensagem de erro
    *
    * @return                      true successo, false erro
    *  
    * @author                      João Eiras
    * @version                     1.0
    * @since                       2007/09/20 
    ********************************************************************************************/
    FUNCTION get_epis_anamnesis_last_update
    (
        i_lang        IN language.id_language%TYPE,
        i_episode     IN epis_anamnesis.id_episode%TYPE,
        i_prof        IN profissional,
        i_flg_type    IN epis_anamnesis.flg_type%TYPE,
        o_last_update OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Obter todas as queixas / anamneses do doente, excepto a mais recente no episódio (se existir)  
    *
    * @param i_lang                 id da lingua
    * @param i_pat                  patient id
    * @param i_episode              episode id
    * @param i_flg_type             C  - queixa ; A - anamnese
    * @param i_prof                 objecto com info do utilizador    
    * @param o_desc                 registos de queixa/historia          
    * @param o_error                Error message
    *                        
    * @return                       true or false on success or error
    * 
    * @author                       Claudia Silva
    * @version                      1.0
    * @since                        2005/03/30  
    ********************************************************************************************/
    FUNCTION get_previous_epis_anamnesis
    (
        i_lang     IN language.id_language%TYPE,
        i_pat      IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN epis_anamnesis.flg_type%TYPE,
        i_prof     IN profissional,
        o_desc     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_last_id_epis_observation
    (
        i_lang        IN language.id_language%TYPE,
        i_episode     IN epis_observation.id_episode%TYPE,
        i_prof        IN profissional,
        o_id_epis_obs OUT epis_observation.id_epis_observation%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Registar observações do episódio  
    *
    * @param i_lang                 id da lingua
    * @param i_episode              episode id
    * @param i_prof                 objecto com info do utilizador
    * @param i_desc                 observação
    * @param i_id_epis_observation  Episódio da observação 
    * @param i_prof_cat_type        Tipo de categoria do profissional, tal como é retornada em PK_LOGIN.GET_PROF_PREF
    * @param i_flg_type_mode        Type of edition
    * @param o_id_epis_observation  novo registo           
    * @param o_error                Error message
    *
    * @value i_flg_type_mode        {*} 'N'  New {*} 'E' Edit {*} 'A' Agree {*} 'U' Update from previous assessment {*} 'O' No changes
    * @return                       true or false on success or error
    * 
    * @author                       Claudia Silva
    * @version                      1.0
    * @since                        2005/03/04
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1   
    *                             2008/05/08
    *                             Added new edit options: Update from previous assessment; No changes;
    ********************************************************************************************/
    FUNCTION set_epis_observation
    (
        i_lang                IN language.id_language%TYPE,
        i_episode             IN epis_observation.id_episode%TYPE,
        i_prof                IN profissional,
        i_desc                IN epis_observation.desc_epis_observation%TYPE,
        i_id_epis_observation IN epis_observation.id_epis_observation%TYPE,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_flg_type_mode       IN VARCHAR2,
        o_id_epis_observation OUT epis_observation.id_epis_observation%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_observation
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN epis_observation.id_episode%TYPE,
        i_prof    IN profissional,
        o_temp    OUT pk_types.cursor_type,
        o_def     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /***********************************************************************************
       OBJECTIVO:   Obter todas as observações do episódio excepto a última temporária 
              do profissional no episódio 
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
               I_EPISODE - ID do episódio
             I_PROF - profissional que acede 
                Saida: O_TEMP - último registo temporário
               O_DEF - último registo definitivo registado antes da passagem de temporários para definitivos + 
                     todos os registos definitivos registado após a passagem de temporários para definitivos
               O_ERROR - erro 
      
      CRIAÇÃO: CRS 2005/03/04 
      NOTAS: 
    ************************************************************************************/

    FUNCTION get_epis_observation_det
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN epis_anamnesis.id_episode%TYPE,
        i_prof    IN profissional,
        o_det     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obter detalhe do exame físico do episódio 
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
               I_EPISODE - ID do episódio actual 
             I_PROF - ID do profissional
              Saida: O_DET - registos de exame físico  
             O_ERROR - erro 
      
      CRIAÇÃO: SS 2006/10/12 
      NOTAS: 
    *********************************************************************************/

    FUNCTION get_epis_observation_temp
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN epis_observation.id_episode%TYPE,
        i_prof    IN profissional,
        o_desc    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_last_epis_observation
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN epis_observation.id_episode%TYPE,
        i_prof    IN profissional,
        o_temp    OUT pk_types.cursor_type,
        o_def     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_available_info
    (
        i_lang        IN language.id_language%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_prof        IN profissional,
        o_complaint   OUT pk_types.cursor_type,
        o_history     OUT pk_types.cursor_type,
        o_observation OUT pk_types.cursor_type,
        o_text_vs     OUT table_varchar,
        o_author_vs   OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_epis_problem
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN epis_anamnesis.id_episode%TYPE,
        i_prof          IN profissional,
        i_desc          IN epis_problem.desc_epis_problem%TYPE,
        i_pat_problem   IN epis_problem.id_pat_problem%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_problem
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN epis_anamnesis.id_episode%TYPE,
        i_prof    IN profissional,
        o_desc    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_epis_obs_exam
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN epis_obs_exam.id_episode%TYPE,
        i_prof             IN profissional,
        i_exam             IN epis_obs_exam.id_periodic_exam_educ%TYPE,
        i_desc             IN epis_obs_exam.desc_epis_obs_exam%TYPE,
        i_flg_brd          IN epis_obs_exam.flg_brd%TYPE,
        i_flg_na           IN epis_obs_exam.flg_na%TYPE,
        i_id_epis_obs_exam IN epis_obs_exam.id_epis_obs_exam%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_obs_exam
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN epis_obs_exam.id_episode%TYPE,
        i_exam    IN epis_obs_exam.id_periodic_exam_educ%TYPE,
        i_prof    IN profissional,
        o_desc    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_epis_diagnosis
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN epis_diagnosis.id_episode%TYPE,
        i_prof          IN profissional,
        i_diagnosis     IN epis_diagnosis.id_diagnosis%TYPE,
        i_type          IN epis_diagnosis.flg_type%TYPE,
        i_notes         IN epis_diagnosis.notes%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_epis_diagnosis_array
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN epis_diagnosis.id_episode%TYPE,
        i_prof          IN profissional,
        i_diagnosis     IN table_number,
        i_type          IN table_varchar,
        i_notes         IN table_varchar,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_desc_diag     IN epis_diagnosis.desc_epis_diagnosis%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_diag_list
    (
        i_lang      IN language.id_language%TYPE,
        i_episode   IN epis_diagnosis.id_episode%TYPE,
        i_type      IN epis_diagnosis.flg_type%TYPE,
        i_status    IN epis_diagnosis.flg_status%TYPE,
        i_prof      IN profissional,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_diag_det
    (
        i_lang      IN language.id_language%TYPE,
        i_epis_diag epis_diagnosis.id_epis_diagnosis%TYPE,
        i_prof      IN profissional,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_epis_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_prof           IN profissional,
        i_notes_cancel   IN epis_diagnosis.notes_cancel%TYPE,
        i_prof_cat_type  IN category.flg_type%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_epis_diag
    (
        i_lang      IN language.id_language%TYPE,
        i_episode   IN epis_diagnosis.id_episode%TYPE,
        i_prof      IN profissional,
        i_diagnosis IN epis_diagnosis.id_diagnosis%TYPE,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg_text  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_vs_read
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN vital_sign_read.id_episode%TYPE,
        i_prof    IN profissional,
        o_vs      OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_vs_read_group
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN vital_sign_read.id_episode%TYPE,
        i_prof    IN profissional,
        o_vs      OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_all_vs_read
    (
        i_lang    IN language.id_language%TYPE,
        i_pat     IN vital_sign_read.id_patient%TYPE,
        i_episode IN vital_sign_read.id_episode%TYPE,
        i_vs      IN vital_sign_read.id_vital_sign%TYPE,
        i_prof    IN profissional,
        o_vs      OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_read
    (
        i_lang    IN language.id_language%TYPE,
        i_pat     IN vital_sign_read.id_patient%TYPE,
        i_episode IN vital_sign_read.id_episode%TYPE,
        i_vs      IN vital_sign_read.id_vital_sign%TYPE,
        i_prof    IN profissional,
        o_info    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_diag_anamnesis
    (
        i_lang    IN language.id_language%TYPE,
        i_pat     IN patient.id_patient%TYPE,
        i_episode IN epis_anamnesis.id_episode%TYPE,
        o_text    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_anamnesis_code
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN epis_anamnesis.id_episode%TYPE,
        i_prof    IN profissional,
        o_code    OUT VARCHAR2,
        o_id_diag OUT epis_anamnesis.id_diagnosis%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Listar as revisões de sistemas do episódio
    *
    * @param i_lang                 id da lingua
    * @param i_prof                 objecto com info do utilizador
    * @param i_epis                 episode id 
    * @param o_review_sys           cursor with review of systems values
    * @param o_error                Error message
    *                        
    * @return                       true or false on success or error
    * 
    * @author                       Emília Taborda
    * @version                      1.0
    * @since                        10-01-2007
    ********************************************************************************************/
    FUNCTION get_epis_review_systems
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_epis       IN episode.id_episode%TYPE,
        o_review_sys OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
    * Retorna informação relativa ao último registo de revisão de sistemas neste episódio, em texto livre
    *
    * @param i_lang id da lingua 
    * @param i_episode id do episódio
    * @param i_prof objecto do profissional
    * @param o_last_update cursor con informação  
    * @param o_error mensagem de erro
    *
    * @return true successo, false erro
    *  
    * @author João Eiras
    * @since 2007/09/20 
    */
    FUNCTION get_epis_rvsystems_last_update
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        o_last_update OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Registar as revisões de sistemas associadas a um episódio 
    *
    * @param i_lang                 id da lingua
    * @param i_prof                 objecto com info do utilizador
    * @param i_epis                 episode id 
    * @param i_desc_rev_sys         Review of systems notes
    * @param i_prof_cat_type        categoty of professional
    * @param i_flg_type             Type of edition
    * @param i_epis_rsystem         episode review system id
    * @param o_error                Error message
    *
    * @value i_flg_type_mode        {*} 'N'  New {*} 'E' Edit {*} 'A' Agree {*} 'U' Update from previous assessment {*} 'O' No changes                        
    * @return                       true or false on success or error
    * 
    * @author                       Emília Taborda
    * @version                      1.0
    * @since                        10-01-2007
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1   
    *                             2008/05/08
    *                             Added new edit options: Update from previous assessment; No changes;
    ********************************************************************************************/
    FUNCTION set_epis_review_systems
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_desc_rev_sys  IN epis_review_systems.desc_review_systems%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_flg_type      IN VARCHAR2,
        i_epis_rsystem  IN epis_review_systems.id_epis_review_systems%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Listar as observações de um dado episódio
    *
    * @param i_lang                 id da lingua
    * @param i_prof                 objecto com info do utilizador
    * @param i_episode              episode id 
    * @param i_flg_obs              Se a observação do episódio é: D - Definitiva; T - Temporária
    * @param o_phy_exam_text        cursor with observation values
    * @param o_error                Error message
    *                        
    * @return                       true or false on success or error
    * 
    * @author                       Emília Taborda
    * @version                      1.0   
    * @since                        2007/01/30
    ********************************************************************************************/
    FUNCTION get_physical_exam_text
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_flg_obs       IN epis_observation.flg_temp%TYPE,
        o_phy_exam_text OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Listar as revisões de sistema de um dado episódio
    *
    * @param i_lang                 id da lingua
    * @param i_prof                 objecto com info do utilizador
    * @param i_episode              episode id 
    * @param o_rev_sys_text         cursor with review of systems values
    * @param o_error                Error message
    *                        
    * @return                       true or false on success or error
    * 
    * @author                       Emília Taborda
    * @version                      1.0   
    * @since                        2007/01/30
    ********************************************************************************************/
    FUNCTION get_review_system_text
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        o_rev_sys_text OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Checks if an episode has review of systems.
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param o_flg_data            Y if there are data, F when no date found
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       18-09-2007
    **********************************************************************************************/
    FUNCTION get_review_system_exists
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_flg_data OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Indica se o profissional actual registou uma revisão de sistemas no episódio pretendido
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param o_last_prof_episode   último episódio registado de revisão de sistemas 
    * @param o_flg_data            Y if there are data, F when no date found
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       18-09-2007
    **********************************************************************************************/
    FUNCTION get_prof_rev_system_exists
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        o_last_prof_episode OUT episode.id_episode%TYPE,
        o_flg_data          OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Checks if an episode has physical exam
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param i_doc_area            area ID (physical exam, physical assessment)
    * @param o_flg_data            Y if there are data, F when no date found
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       18-09-2007
    **********************************************************************************************/
    FUNCTION get_physical_exam_exists
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_doc_area      IN doc_area.id_doc_area%TYPE,
        o_flg_data      OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Indica se o profissional actual registou um exame fisico no episódio pretendido
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param o_last_prof_episode   último episódio registado de exame físico
    * @param o_flg_data            Y if there are data, F when no date found
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       18-09-2007
    **********************************************************************************************/
    FUNCTION get_prof_physical_exam_exists
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_prof_cat_type     IN category.flg_type%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        o_last_prof_episode OUT episode.id_episode%TYPE,
        o_flg_data          OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Indica se o profissional actual registou uma queixa/história no episódio pretendido
    *
    * @param i_lang                    id da lingua 
    * @param i_episode                 id do episódio
    * @param i_prof                    objecto do profissional
    * @param i_flg_type                informação que se quer saber: C para queixa e A para anamnese 
    * @param o_last_prof_episode       último episódio de queixa ou história
    * @param o_flg_data                flag com valores Y/N que indica se há ou não, respectivamente, os registos  
    * @param o_error                   mensagem de erro
    *
    * @return                          true successo, false erro
    *  
    * @author                          Emilia Taborda
    * @version                         1.0
    * @since                           2007/09/24 
    ********************************************************************************************/
    FUNCTION get_prof_epis_anamn_exists
    (
        i_lang              IN language.id_language%TYPE,
        i_episode           IN epis_anamnesis.id_episode%TYPE,
        i_prof              IN profissional,
        i_flg_type          IN epis_anamnesis.flg_type%TYPE,
        o_last_prof_episode OUT episode.id_episode%TYPE,
        o_flg_data          OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Toda a informação para um ID episódio de queixa / história
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_prof_cat_type       category of professional
    * @param i_epis_anamnesis      episode anamnesis id
    * @param o_information         array with all information to episode anamnesis
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       2007/09/24
    **********************************************************************************************/
    FUNCTION get_epis_anamnesis_free_text
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_epis_anamnesis IN epis_anamnesis.id_epis_anamnesis%TYPE,
        o_information    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Toda a informação para um ID episódio de exame fisico
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_prof_cat_type       category of professional
    * @param i_epis_observation    episode observation id
    * @param o_information         array with all information to episode observation
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       2007/09/24
    **********************************************************************************************/
    FUNCTION get_epis_observ_free_text
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_epis_observation IN epis_observation.id_epis_observation%TYPE,
        o_information      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Toda a informação para um ID episódio de revisão de sistemas
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_prof_cat_type       category of professional
    * @param i_epis_rev_system     episode review of system id
    * @param o_information         array with all information to episode review of system
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       2007/09/24
    **********************************************************************************************/
    FUNCTION get_epis_review_sys_free_text
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        i_epis_rev_system IN epis_review_systems.id_epis_review_systems%TYPE,
        o_information     OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Checks last episode of review of systems.
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param o_rev_system          last episode review of systems
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       2007/10/01
    **********************************************************************************************/
    FUNCTION get_summ_last_review_system
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_rev_system OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Checks last episode of physical exam.
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param i_prof_cat_type       Categoria do profissional
    * @param o_physical_exam       last physical exam episode 
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       2007/10/01
    **********************************************************************************************/
    FUNCTION get_summ_last_physical_exam
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_physical_exam OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Checks last episode of anamnesis or complaint
    *
    * @param i_lang                    id da lingua 
    * @param i_episode                 id do episódio
    * @param i_prof                    objecto do profissional
    * @param i_flg_type                informação que se quer saber: C para queixa e A para anamnese 
    * @param o_anamnesis               Last complaint episode  
    * @param o_error                   mensagem de erro
    *
    * @return                          true successo, false erro
    *  
    * @author                          Emilia Taborda
    * @version                         1.0
    * @since                           2007/10/01
    ********************************************************************************************/
    FUNCTION get_summ_last_anamnesis
    (
        i_lang      IN language.id_language%TYPE,
        i_episode   IN epis_anamnesis.id_episode%TYPE,
        i_prof      IN profissional,
        i_flg_type  IN epis_anamnesis.flg_type%TYPE,
        o_anamnesis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns cursor with last record made in the social or family history area, according to the i_flg_type parameter
    *
    * @param i_lang                    language id
    * @param i_prof                    user's data
    * @param i_patient                 patient id
    * @param i_flg_type                which area to check: F - family, S - social, R - surgical
    * @param o_history               cursor with data  
    * @param o_error                   mensagem de erro
    *
    * @return                          true successo, false erro
    *  
    * @author                          João Eiras, 
    * @version                         1.0
    * @since                           2008/01/28
    ********************************************************************************************/
    FUNCTION get_summ_last_soc_fam_sr_hist
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_flg_type IN pat_fam_soc_hist.flg_type%TYPE,
        o_history  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns cursor with last record of exam or assessment in this episode, in free text
    *
    * @param i_lang                language id
    * @param i_episode             episóde id
    * @param i_prof                professional object
    * @param i_flg_type            type of information to return
    * @param o_last_update         cursor with data
    * @param o_error               error message
    *
    * @value i_flg_type           {*} 'E' exam {A} Assessment
    *
    * @return                      true success, false error
    *  
    * @author                      Ariel Machado
    * @version                     1.0
    * @since                       2008/04/15 
    ********************************************************************************************/
    FUNCTION get_epis_obs_last_update
    (
        i_lang        IN language.id_language%TYPE,
        i_episode     IN epis_observation.id_episode%TYPE,
        i_prof        IN profissional,
        i_flg_type    IN epis_observation.flg_type%TYPE,
        o_last_update OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Criar queixa / anamnese 
    *
    * @param i_lang                 id da lingua
    * @param i_episode              episode id
    * @param i_prof                 objecto com info do utilizador
    * @param i_desc                 descrição da queixa / anamnese 
    * @param i_flg_type             C  - queixa ; A - anamnese
    * @param i_flg_type_mode        A - Agree, E - edit, N - new
    * @param i_id_epis_anamnesis    Episódio da queixa/historia 
    * @param i_id_diag              ID do diagnóstico associado ao texto + freq.seleccionado para registo da queixa / história 
    * @param i_flg_class            A - motivo administrativo de consulta (CARE: texto + freq. do ICPC2)
    * @param i_prof_cat_type        Tipo de categoria do profissional, tal como é retornada em PK_LOGIN.GET_PROF_PREF
    * @param i_dt_init              data de início de consulta
    * @param o_id_epis_anamnesis    registo           
    * @param o_error                Error message
    *                        
    * @return                       true or false on success or error
    * 
    * @author                       Teresa Coutinho
    * @version                      1.0
    * @since                        2008/05/08
    ********************************************************************************************/
    FUNCTION set_epis_anamnesis
    (
        i_lang              IN language.id_language%TYPE,
        i_episode           IN epis_anamnesis.id_episode%TYPE,
        i_prof              IN profissional,
        i_desc              IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_flg_type          IN epis_anamnesis.flg_type%TYPE,
        i_flg_type_mode     IN VARCHAR2,
        i_id_epis_anamnesis IN epis_anamnesis.id_epis_anamnesis%TYPE,
        i_id_diag           IN epis_anamnesis.id_diagnosis%TYPE,
        i_flg_class         IN epis_anamnesis.flg_class%TYPE,
        i_prof_cat_type     IN category.flg_type%TYPE,
        i_dt_init           IN VARCHAR2,
        o_id_epis_anamnesis OUT epis_anamnesis.id_epis_anamnesis%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Obter queixa / anamnese de episódio anterior (ou de 1º episódio) no caso deste ser subsequente
    *
    * @param i_lang                 id da lingua
    * @param i_episode              episode id
    * @param i_prof                 objecto com info do utilizador
    * @param o_id_epis_anamnesis    registo           
    * @param o_error                Error message
    *                        
    * @return                       true or false on success or error
    * 
    * @author                       Pedro Teixeira
    * @version                      1.0
    * @since                        2008/06/17
    ********************************************************************************************/
    FUNCTION get_subsequent_epis_anamnesis
    (
        i_lang                IN language.id_language%TYPE,
        i_episode             IN epis_anamnesis.id_episode%TYPE,
        i_prof                IN profissional,
        o_id_epis_anamnesis   OUT epis_anamnesis.id_epis_anamnesis%TYPE,
        o_desc_epis_anamnesis OUT epis_anamnesis.desc_epis_anamnesis%TYPE,
        o_id_visit            OUT visit.id_visit%TYPE,
        o_id_clinical_service OUT episode.id_clinical_service%TYPE,
        o_id_patient          OUT patient.id_patient%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Retorna a lista dos motivos codificados ou a lista dos textos mais frequentes. Isto
    * consoante a configuração.
    *
    * @param i_lang                ID language
    * @param i_prof                Professional's details     
    * @param i_pat                 ID of patient 
    * @param i_episode             ID of episode
    *
    * @param o_text                Array of icf the column Folha if 0 means that has child, 1 - doesn't have child
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Elisabete Bugalho
    * @version                     2.4.4
    * @since                       2009/01/23
    **********************************************************************************************/
    FUNCTION get_evaluation_notes
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat     IN patient.id_patient%TYPE,
        i_episode IN epis_anamnesis.id_episode%TYPE,
        o_text    OUT pk_types.cursor_type,
        o_type    OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_reason_for_visit
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN NUMBER,
        i_id_schedule IN NUMBER,
        i_separator   IN VARCHAR2 DEFAULT '.'
    ) RETURN CLOB;

    /**********************************************************************************************
    * Retorna o motivo da consulta ou o do agendamento
    *
    * @param i_lang                ID language
    * @param i_id_schedule         ID schedule
    * @param i_episode             ID of episode
    *
    * @param o_epis_reason         The reason for visit
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Elisabete Bugalho
    * @version                     2.4.4
    * @since                       2009/03/20
    **********************************************************************************************/
    FUNCTION get_epis_reason_for_visit
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN NUMBER,
        i_id_schedule IN NUMBER,
        o_epis_reason OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns complaint related anamnesis. Used in ambulatory products.
    * Not called directly by the UI layer.
    *
    * @param i_lang                language identifier
    * @param i_prof                logged professional structure
    * @param i_episode             episode identifier
    * @param o_anamnesis           cursor
    * @param o_error               error
    *
    * @return                      false if errors occur, true otherwise
    *                        
    * @author                      Pedro Carneiro
    * @version                      2.5.0.6
    * @since                       2009/09/18
    **********************************************************************************************/
    FUNCTION get_anamnesis_summ
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN epis_anamnesis.id_episode%TYPE,
        o_anamnesis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Criar queixa / anamnese 
    * Internal function (does not commit).
    *
    * @param i_lang                      id da lingua
    * @param i_episode                   episode id
    * @param i_prof                      objecto com info do utilizador
    * @param i_desc                      descrição da queixa / anamnese 
    * @param i_flg_type                  C  - queixa ; A - anamnese
    * @param i_flg_type_mode             type of edition
    * @param i_id_epis_anamnesis         Episódio da queixa/historia 
    * @param i_id_diag                   ID do diagnóstico associado ao texto + freq.seleccionado para registo da queixa / história 
    * @param i_flg_class                 A - motivo administrativo de consulta (CARE: texto + freq. do ICPC2)
    * @param i_prof_cat_type             Tipo de categoria do profissional, tal como é retornada em PK_LOGIN.GET_PROF_PREF
    * @param i_flg_rep_by                record reported by
    * @param i_dt_epis_anamnesis_tstz    Date/Time of Admition
    * @param o_id_epis_anamnesis         registo           
    * @param o_error                     Error message
    * 
    * @value i_flg_type_mode             {*} 'N'  New {*} 'E' Edit {*} 'A' Agree {*} 'U' Update from previous assessment {*} 'O' No changes
    * @return                            true or false on success or error
    * 
    * @author                            Claudia Silva
    * @version                           1.0
    * @since                             2005/03/04 
    *
    * Changes:
    *                                    Ariel Machado
    *                                    1.1   
    *                                    2008/05/08
    *                                    Added new edit options: Update from previous assessment; No changes;
    * Changed:
    *                                    Elisabete bugalho
    *                                    2009/03/20
    *                                    Ignore the codification of reason of visit and deactivate previous 
    *                                    anamnesis, depending on the configuration (OUTP, PP-PT)
    ********************************************************************************************/
    FUNCTION set_epis_anamnesis_int
    (
        i_lang                   IN language.id_language%TYPE,
        i_episode                IN epis_anamnesis.id_episode%TYPE,
        i_prof                   IN profissional,
        i_desc                   IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_flg_type               IN epis_anamnesis.flg_type%TYPE,
        i_flg_type_mode          IN epis_anamnesis.flg_edition_type%TYPE,
        i_id_epis_anamnesis      IN epis_anamnesis.id_epis_anamnesis%TYPE,
        i_id_diag                IN epis_anamnesis.id_diagnosis%TYPE,
        i_flg_class              IN epis_anamnesis.flg_class%TYPE,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_flg_rep_by             IN epis_anamnesis.flg_reported_by%TYPE,
        i_dt_epis_anamnesis_tstz IN epis_anamnesis.dt_epis_anamnesis_tstz%TYPE DEFAULT NULL,
        o_id_epis_anamnesis      OUT epis_anamnesis.id_epis_anamnesis%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns complaint related anamnesis associated to the episodes of an patient to a given epis
    * type. 
    * Not called directly by the UI layer.
    *
    * @param i_lang                language identifier
    * @param i_prof                logged professional structure
    * @param i_id_patient          Patient identifier
    * @param i_id_epis_type        Epis type identifier
    * @param i_flg_which           ALL- all the episodes
    *                              CUR- active episodes
    *                              PRV- inactive episodes                             
    * @param o_anamnesis           output cursor
    * @param o_error               error
    *
    * @return                      false if errors occur, true otherwise
    *                        
    * @author                      Sofia Mendes
    * @version                      2.5.1
    * @since                       08-Sep-2010
    **********************************************************************************************/
    FUNCTION get_anamnesis_pat
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_id_epis_type IN epis_type.id_epis_type%TYPE,
        i_flg_which    IN VARCHAR2,
        o_anamnesis    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    --
    g_exception EXCEPTION;
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_error        VARCHAR2(2000);
    g_found        BOOLEAN;
    --
    g_complaint CONSTANT epis_anamnesis.flg_type%TYPE := 'C';
    g_anamnesis CONSTANT epis_anamnesis.flg_type%TYPE := 'A';
    --
    g_epis_diag_prob CONSTANT epis_diagnosis.flg_type%TYPE := 'P';
    g_epis_diag_defi CONSTANT epis_diagnosis.flg_type%TYPE := 'D';
    g_epis_diag_act  CONSTANT epis_diagnosis.flg_type%TYPE := 'A';
    g_epis_diag_can  CONSTANT epis_diagnosis.flg_type%TYPE := 'C';
    --
    g_flg_hist        CONSTANT epis_anamnesis.flg_temp%TYPE := 'H';
    g_flg_temp        CONSTANT epis_anamnesis.flg_temp%TYPE := 'T';
    g_flg_def         CONSTANT epis_anamnesis.flg_temp%TYPE := 'D';
    g_pat_prob_active CONSTANT pat_problem.flg_status%TYPE := 'A';
    g_pat_prob_cancel CONSTANT pat_problem.flg_status%TYPE := 'C';
    g_aproved_clin    CONSTANT pat_problem.flg_aproved%TYPE := 'M';
    --
    g_diag_admin CONSTANT diagnosis.flg_other%TYPE := 'A';
    --
    g_epis_active   CONSTANT VARCHAR2(1) := 'A';
    g_epis_outdated CONSTANT VARCHAR2(1) := 'O';
    --
    g_flg_edition_type_new       CONSTANT epis_anamnesis.flg_edition_type%TYPE := 'N';
    g_flg_edition_type_edit      CONSTANT epis_anamnesis.flg_edition_type%TYPE := 'E';
    g_flg_edition_type_agree     CONSTANT epis_anamnesis.flg_edition_type%TYPE := 'A';
    g_flg_edition_type_update    CONSTANT epis_anamnesis.flg_edition_type%TYPE := 'U';
    g_flg_edition_type_nochanges CONSTANT epis_anamnesis.flg_edition_type%TYPE := 'O';
    --
    g_flg_temp_d CONSTANT epis_anamnesis.flg_temp%TYPE := 'D';
    g_flg_temp_t CONSTANT epis_anamnesis.flg_temp%TYPE := 'T';
    g_flg_type_a CONSTANT epis_anamnesis.flg_type%TYPE := 'A';
    g_flg_type_c CONSTANT epis_anamnesis.flg_type%TYPE := 'C';
    --
    g_doc_area_complaint CONSTANT doc_area.id_doc_area%TYPE := 20; -- Complaint
    g_doc_area_hist_ill  CONSTANT doc_area.id_doc_area%TYPE := 21; --History present illness
    g_doc_area_rev_sys   CONSTANT doc_area.id_doc_area%TYPE := 22; --Review of system
    g_doc_area_phy_exam  CONSTANT doc_area.id_doc_area%TYPE := 28; --physical exam   
    g_doc_area_past_surg CONSTANT doc_area.id_doc_area%TYPE := 46; -- Past surgical
    g_doc_area_past_fam  CONSTANT doc_area.id_doc_area%TYPE := 47; -- Past family
    g_doc_area_past_soc  CONSTANT doc_area.id_doc_area%TYPE := 48; -- Past social
    --
    g_alert_diag_unknown        CONSTANT alert_diagnosis.id_alert_diagnosis%TYPE := 0;
    g_alert_diag_none           CONSTANT alert_diagnosis.id_alert_diagnosis%TYPE := -1;
    g_alert_diag_type_med       CONSTANT alert_diagnosis.flg_type%TYPE := 'M'; -- medical
    g_alert_diag_type_surg      CONSTANT alert_diagnosis.flg_type%TYPE := 'S'; -- surgical
    g_alert_diag_type_cong_anom CONSTANT alert_diagnosis.flg_type%TYPE := 'A'; -- congenital anomaly
    --
    g_pat_hist_type_fam  CONSTANT pat_fam_soc_hist.flg_type%TYPE := 'F'; -- family
    g_pat_hist_type_soc  CONSTANT pat_fam_soc_hist.flg_type%TYPE := 'S'; -- social
    g_pat_hist_diag_surg CONSTANT pat_history_diagnosis.flg_type%TYPE := 'S'; -- surgical
    --
    g_cat_flg_type_d CONSTANT category.flg_type%TYPE := 'D';
    g_cat_flg_type_n CONSTANT category.flg_type%TYPE := 'N';
    g_cat_flg_type_u CONSTANT category.flg_type%TYPE := 'U';
    --
    g_observ_flg_type_e CONSTANT epis_observation.flg_type%TYPE := 'E';
    g_observ_flg_type_a CONSTANT epis_observation.flg_type%TYPE := 'A';
    g_abbreviation      CONSTANT institution.abbreviation%TYPE := 'A';
    --
    g_flg_ehr_n CONSTANT episode.flg_ehr%TYPE := 'N';
    g_flg_ehr_s CONSTANT episode.flg_ehr%TYPE := 'S';
    g_flg_ehr_e CONSTANT episode.flg_ehr%TYPE := 'E';
    --
    -- cmf 01-07-2008 variable for insert into epis_recomend ( Medical Notes )
    g_physexam_session CONSTANT notes_config.notes_code%TYPE := 'PHY';
    g_revsys_session   CONSTANT notes_config.notes_code%TYPE := 'RSY';
    g_hpi_session      CONSTANT notes_config.notes_code%TYPE := 'HPI';

END;
/
