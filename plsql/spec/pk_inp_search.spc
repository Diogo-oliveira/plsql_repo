/*-- Last Change Revision: $Rev: 2028755 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:44 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_inp_search AS

    FUNCTION get_pat_criteria_active_aux
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN VARCHAR2,
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

    /******************************************************************************
       NAME:       PK_INP_SEARCH
       PURPOSE:
    
       REVISIONS:
       Ver        Date        Author           Description
       ---------  ----------  ---------------  ------------------------------------
       1.0        08-11-2006             1. Created this package.
    ******************************************************************************/
    FUNCTION get_pat_criteria_active_clin
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN VARCHAR2,
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
    /******************************************************************************
       OBJECTIVO:   Efectuar pesquisa de doentes ACTIVOS, de acordo com os critérios seleccionados ,
                    para pessoal clínico (médicos e enfermeiros)
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
               I_ID_SYS_BTN_CRIT - Lista de ID'S de critérios de pesquisa.
               I_CRIT_VAL - Lista de valores dos critérios de pesquisa
             I_INSTIT - Instituição
             I_EPIS_TYPE - Tipo de consulta
             I_DT - Data a pesquisar. Se for null assume a data de sistema
               I_PROF - ID do profissional q regista
             I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal
                       como é retornada em PK_LOGIN.GET_PROF_PREF
                Saida:   O_PAT - Doentes activos
                 O_MESS_NO_RESULT - Mensagem quando a pesquisa não devolver resultados
             O_ERROR - Erro
    
      CRIAÇÃO: SS 2006/11/08
      NOTAS: Igual à função do PK_EDIS_PROC mas sem EPIS_ANAMNESIS, EDIS_TRIAGE e TRIAGE_COLOR mas com BED
    *********************************************************************************/

    -- ****************************************************************************
    FUNCTION get_pat_criteria_active_adm
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN VARCHAR2,
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
    -- ##########################################################################
    /******************************************************************************
    * Returns the search results for cancelled episodes in ALERT® Inpatient.
    * 
    * @param i_lang              Professional preferred language
    * @param i_id_sys_btn_crit   Search criteria ID's
    * @param i_crit_val          Search criteria values
    * @param i_instit            Institution to search
    * @param i_epis_type         Type of the episode
    * @param i_dt                Search date
    * @param i_prof              Professional info. 
    * @param i_prof_cat_type     Professional category
    * @param o_flg_show          
    * @param o_msg               
    * @param o_msg_title         
    * @param o_button            
    * @param o_epis_cancel       Results list
    * @param o_mess_no_result    Message to show when there's no results
    * @param o_error             Error message
    * 
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  José Brito [based on GET_PAT_CRITERIA_ACTIVE_ADM by José Silva]
    * @version                 0.1
    * @since                   2008-Apr-23
    *
    ******************************************************************************/
    FUNCTION get_epis_cancelled
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_epis_cancel     OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    --
    --
    /******************************************************************************
    * Returns the physician's search results for cancelled episodes in ALERT® Inpatient.
    * 
    * @param i_lang              Professional preferred language
    * @param i_id_sys_btn_crit   Search criteria ID's
    * @param i_crit_val          Search criteria values
    * @param i_instit            Institution to search
    * @param i_epis_type         Type of the episode
    * @param i_dt                Search date
    * @param i_prof              Professional info. 
    * @param i_prof_cat_type     Professional category
    * @param o_flg_show          
    * @param o_msg               
    * @param o_msg_title         
    * @param o_button             
    * @param o_epis_cancel       Results list
    * @param o_mess_no_result    Message to show when there's no results
    * @param o_error             Error message
    * 
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  José Brito [based on GET_PAT_CRITERIA_ACTIVE_CLIN]
    * @version                 0.1
    * @since                   2008-Apr-24
    *
    ******************************************************************************/
    FUNCTION get_epis_cancelled_clin
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_epis_cancel     OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Search of active patients to the activity therapist
    *
    * @param i_lang                          Language ID
    * @param I_ID_SYS_BTN_CRIT               List of the search criteria IDs
    * @param I_CRIT_VAL                      List of the search criteria values
    * @param I_INSTIT                        Institution
    * @param I_EPIS_TYPE                     Episode type
    * @param I_DT                            Date to be searched. If it is null the system date is assumed
    * @param I_PROF                          Professional ID
    * @param I_PROF_CAT_TYPE                 Professional category type, as it is returned in PK_LOGIN.GET_PROF_PREF
    * @param O_PAT                           Active patients
    * @param O_MESS_NO_RESULT                Message to be shown when the search does not return results
    * @param O_ERROR                         Error
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.6.0.3
    * @since                                 20-Mai-2010 
    * Similar to the functionget_pat_criteria_active_clin to the activity therapist
    **********************************************************************************************/
    FUNCTION get_pat_criteria_active_at
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN VARCHAR2,
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
    --
    --
    g_package_owner VARCHAR2(0050);
    g_package_name  VARCHAR2(0050);
    --
    g_error        VARCHAR2(4000);
    g_sysdate      DATE;
    g_sysdate_char VARCHAR2(50);
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_found        BOOLEAN;
    g_exception EXCEPTION;
    g_ret BOOLEAN;
    --

    g_inp_epis_type NUMBER;
    g_epis_active   episode.flg_status%TYPE;
    g_epis_inactive episode.flg_status%TYPE;
    g_epis_canceled episode.flg_status%TYPE;
    g_epis_pend     episode.flg_status%TYPE;
    --
    --jose silva 27-03-2007 nova variavel global
    g_doc_active    doc_external.flg_status%TYPE;
    g_diag_flg_type epis_diagnosis.flg_type%TYPE;
    --
    g_epis_diag_co epis_diagnosis.flg_status%TYPE;
    --
    g_pl VARCHAR2(0050);

    g_status_movement_t VARCHAR2(0050);

    g_cat_doctor category.flg_type%TYPE;
    g_cat_nurse  category.flg_type%TYPE;

    g_epis_flg_type_def episode.flg_type%TYPE;

    g_task_analysis CONSTANT VARCHAR2(1) := 'A';
    g_task_exam     CONSTANT VARCHAR2(1) := 'E';
    g_task_harvest  CONSTANT VARCHAR2(1) := 'H';

    g_disch_flg_status_cancel CONSTANT discharge.flg_status%TYPE := 'C';
    g_disch_flg_status_reopen CONSTANT discharge.flg_status%TYPE := 'R';
    g_disch_flg_status_active CONSTANT discharge.flg_status%TYPE := 'A';

    g_inp_epis_type_code CONSTANT VARCHAR2(200) := 'EPIS_TYPE.CODE_EPIS_TYPE.5';

    --Handoff responsabilities constants
    g_show_in_grid    CONSTANT VARCHAR2(1) := 'G';
    g_show_in_tooltip CONSTANT VARCHAR2(1) := 'T';

END pk_inp_search;
/
