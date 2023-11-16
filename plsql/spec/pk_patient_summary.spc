/*-- Last Change Revision: $Rev: 2028853 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:20 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_patient_summary IS

    /********************************************************************************************
    * Returns the advanced directives associated with a pacient
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_pacient         pacient's id
    * @param i_doc_area          the doc area id 
     * @param i_num_reg          number of lines to be feteched. If the values is null, all available lines will be fetched         
    * @param o_advanced          array with info advanced directives
        
    * @param o_error             Error message
                        
    * @return                    true or false on success or error
    *
    * @author                    Emília Taborda
    * @since                     2007/07/18
    * @MODIFIED BY  Rui Abreu    27/08/2007
    ********************************************************************************************/

    FUNCTION get_advanced_directives
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_doc_area   IN doc_area.id_doc_area%TYPE,
        i_num_reg    IN NUMBER,
        o_advanced   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Devolver os exames de imagem e outros de um paciente
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_patient           Pacient's ID
    * @param i_flg_stat_epis          State of episode
     * @param i_num_reg          number of lines to be feteched. If the values is null, all available lines will be fetched      
    * @param o_exam                   Cursor containing the imag exams and other exam of episode
                                          
    * @param o_error                  Error message
                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @since                          2007/06/01    
    * @ modified  by : Rui Abreu 
    **********************************************************************************************/
    FUNCTION get_summary_grid_exam_pat
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_num_reg IN NUMBER,
        o_exam    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Devolver os medicamentos associados a um paciente
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient               the patient's ID
     * @param i_num_reg          number of lines to be feteched. If the values is null, all available lines will be fetched                                           
    * @param o_error                  Error message
    * @param o_drug                   Cursor containing the drugs
    
                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @ modified                     Rui Abreu     27/08/2007  (função passa a ser orientada ao paciente e não a um episodio específico)
    **********************************************************************************************/
    FUNCTION get_summary_grid_drug_pat
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_num_reg    IN NUMBER,
        o_drug       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Devolver as intervenções de um paciente
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient               the patient's ID
       * @param i_num_reg          number of lines to be feteched. If the values is null, all available lines will be fetched  
    * @param o_proc                   Cursor containing the interventions of episode
                                          
    * @param o_error                  Error message
                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @ modified                     Rui Abreu     27/08/2007  (função passa a ser orientada ao paciente e não a um episodio específico)
    **********************************************************************************************/
    FUNCTION get_summary_grid_proc_pat
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_num_reg IN NUMBER,
        o_proc    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Devolver as analises laboratoriais
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient               the patient's ID
    
    ** @param i_num_reg          number of lines to be feteched. If the values is null, all available lines will be fetched 
    * @param o_analy                   Cursor containing the analysis of episode                                          
    * @param o_error                  Error message
                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @ modified                     Rui Abreu     27/08/2007  (função passa a ser orientada ao paciente e não a um episodio específico)
    **********************************************************************************************/
    FUNCTION get_summary_grid_analy_pat
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_num_reg IN NUMBER,
        o_analy   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO: Obter os dados relativos a medicação, exames e imagem, procedimentos , 
                  de forma a preencher a respectiva grelha do ecrã de Resumo 
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                             I_ID_EPISODE - ID do episódio 
                             I_PROF - ID do profissional, instituição e software
                             I_NUM_REG - Número de registo a serem mostrados. Caso este parãmetro seja nulo, serão mostrados todos os existentes
                      SAIDA: O_DRUG - Array da medicação
                             O_ANALY - Array das análises
                             O_PROC - Array de procedimentos
                             O_EXAM - Array dos exames
                             O_ERROR - erro 
      
      CRIAÇÃO: ET 2006/07/03
     MODIFICAÇÃO : Rui Abreu 2007/08/27 : Função passa a ser orientada ao paciente, em vez de ser orientada a um episódio específico do mesmo
      NOTAS: Cada registo pode ter um tempo que falta ou que passa em relação à hora prevista da adminstração do
             medicamento. 
             Além deste tempo, devolve também uma flag que indica: R - Fundo a vermelho. Administração em atrazo
                                                                   G - Fundo a verde. Administração agendada para o futuro.
    *********************************************************************************/
    FUNCTION get_summary_grid_pat
    (
        i_lang       IN language.id_language%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_num_reg    IN NUMBER,
        o_drug       OUT pk_types.cursor_type,
        o_analy      OUT pk_types.cursor_type,
        o_proc       OUT pk_types.cursor_type,
        o_exam       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the previous visits to the institution made by the patient 
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_pacient         pacient's id
    * @param i_num_reg          number of lines to be fetched. If the value is null, all available lines will be fetched    
    * @param    o_with_me     cursor with all the visits handled by the professional
     * @param o_all                cursor with all the pacient's visits, regardless of the professional 
    * @param o_error             Error message
                        
    * @return                    true or false on success or error
    *
    * @author                   Rui Abreu
    * @since                     2007/07/27
    ********************************************************************************************/
    FUNCTION get_previous_visits
    (
        i_lang       IN language.id_language%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        i_num_reg    IN NUMBER,
        o_with_me    OUT pk_types.cursor_type,
        o_all        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns all the patient's care plans, guidelines and protocols
    * 
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_patient        patient's id
    * @param i_num_reg           number of lines to be fetched. If the value is null, all available lines will be fetched
    * @param o_care_plans        cursor with all the patient's care plans, guidelines and protocols 
    * @param o_error             Error message
    *                        
    * @return                    true or false on success or error
    *
    * @author                    Eduardo Lourenço
    * @since                     2008/06/03
    ********************************************************************************************/
    FUNCTION get_care_plans
    (
        i_lang       IN language.id_language%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        i_num_reg    IN NUMBER,
        o_care_plans OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the patient's problems
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_pacient        pacient's id
    * @param i_num_reg           number of lines to be feteched. If the values is null, all available lines will be fetched    
    *
    * @param o_pat_problems      cursor with info concerning the problems
    * @param o_error             Error message
    * @return                    true or false on success or error
    *
    * @author                   Rui Abreu
    * @since                     2007/07/27
    ********************************************************************************************/
    FUNCTION get_patient_problems
    (
        i_lang         IN language.id_language%TYPE,
        i_id_patient   IN patient.id_patient%TYPE,
        i_prof         IN profissional,
        i_num_reg      IN NUMBER,
        i_flg_show_ph  IN VARCHAR2 DEFAULT NULL,
        o_pat_problems OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_care_dash_problems
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_problems OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_care_dash_alerts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_alerts  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_care_dash_mcdt
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_mcdt    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function to return the information for assesment tools for dashboard
    *
    * @param   i_lang        Language ID
    * @param   i_prof        Professional's details
    * @param   i_patient     ID patient
    *
    * @return                True or False
    *
    * @author                Elisabete Bugalho
    * @version               2.6.2.1
    * @since                 2012/03/26
    ********************************************************************************************/
    FUNCTION get_assessment_tools
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        o_assessment_tools OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_default_dashboard
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_default      OUT VARCHAR2,
        o_view_options OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_analysis_tooltip
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_name            IN VARCHAR2,
        i_value           IN CLOB,
        i_ref             IN VARCHAR2,
        i_status          IN VARCHAR2,
        i_harvest         IN VARCHAR2,
        i_result_notes    IN CLOB,
        i_parameter_notes IN CLOB,
        i_unit            IN VARCHAR2
    ) RETURN CLOB;

    /*
    * Returns the medical record summary for a given patient
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_patient             Patient id
    * @param     i_episode             Episode id
    * @param     i_num_reg             Flag that indicates the type of list
    * @param     o_vs                  Cursor
    * @param     o_visit_list          Cursor
    * @param     o_problem_list        Cursor
    * @param     o_medication_list     Cursor
    * @param     o_immunization_list   Cursor
    * @param     o_error               Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.7.4.0
    * @since     2018/09/13
    */

    FUNCTION get_patient_emr_summary
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_num_reg           IN NUMBER,
        o_vs                OUT pk_types.cursor_type,
        o_visit_list        OUT pk_types.cursor_type,
        o_problem_list      OUT pk_types.cursor_type,
        o_medication_list   OUT pk_types.cursor_type,
        o_immunization_list OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
      * Returns all the elements necessary to the dashboard screen
      *
      * @param i_lang              language id
      * @param i_prof              professional, software and institution ids
      * @param i_id_pacient         pacient's id
      * @param i_doc_area          the doc area id 
       * @param i_flg_view   Posição dos sinais vitais:S- Resumo; 
                                                                             H - Saída de turno; 
                                                                            V1 - Grelha completa; 
                                                                            V2 - Grelha reduzida;
                                                                            V3 - Biometria;  
                                                                            T - Triagem;
       * @param i_num_reg          number of lines to be feteched. If the values is null, all available lines will be fetched 
            
          *@param o_sign_v -  Listar os sinais vitais
          * @param o_advanced          array with info advanced directives
          * @param    o_with_me     cursor with all the visits handled by the professional
          * @param o_all                cursor with all the pacient's visits, regardless of the professional 
          * @param   o_pat_allergies     cursor with info concerning the allergies
          * @param o_drug                   Cursor containing the drugs
          * @param o_analy                   Cursor containing the analysis of episode
          * @param o_proc                   Cursor containing the interventions of episode
          * @param o_exam                   Cursor containing the imag exams and other exam of episode    
          
      * @param o_error             Error message
                          
      * @return                    true or false on success or error
      *
      * @author                    Rui Abreu
      * @since                     27/08/2007
        
    ********************************************************************************************/
    FUNCTION get_patient_dashboard
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_id_episode   IN episode.id_episode%TYPE,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_flg_view     IN vs_soft_inst.flg_view%TYPE,
        i_num_reg      IN NUMBER,
        o_vs           OUT pk_types.cursor_type,
        o_advanced     OUT pk_types.cursor_type,
        o_with_me      OUT pk_types.cursor_type,
        o_all          OUT pk_types.cursor_type,
        o_pat_problems OUT pk_types.cursor_type,
        o_drug         OUT pk_types.cursor_type,
        o_analy        OUT pk_types.cursor_type,
        o_proc         OUT pk_types.cursor_type,
        o_exam         OUT pk_types.cursor_type,
        o_care_plans   OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function to return the information for ambulatory SOAP Dashboard
    *
    * @param   i_lang        Language ID
    * @param   i_prof        Professional's details
    * @param   i_patient     ID patient
    * @param   i_episode     ID episode
    *
    * @return                True or False
    *
    * @author                Elisabete Bugalho
    * @version               2.6
    * @since                 2010/02/23
    ********************************************************************************************/
    FUNCTION get_amb_dashboard
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        o_cnt_info        OUT pk_types.cursor_type,
        o_problems        OUT pk_types.cursor_type,
        o_prev_contact    OUT pk_types.cursor_type,
        o_alerts          OUT pk_types.cursor_type,
        o_vacc            OUT pk_types.cursor_type,
        o_mcdt            OUT pk_types.cursor_type,
        o_health_program  OUT pk_types.cursor_type,
        o_care_plans      OUT pk_types.cursor_type,
        o_prev_medication OUT pk_types.cursor_type,
        o_dashboard_tabs  OUT pk_types.cursor_type,
        o_vs              OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function to return the information for oncology  Dashboard
    *
    * @param   i_lang        Language ID
    * @param   i_prof        Professional's details
    * @param   i_patient     ID patient
    * @param   i_episode     ID episode
    *
    * @return                True or False
    *
    * @author                Elisabete Bugalho
    * @version               2.6.2
    * @since                 2012/03/22
    ********************************************************************************************/
    FUNCTION get_oncology_dashboard
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        o_problems           OUT pk_types.cursor_type,
        o_prev_contact       OUT pk_types.cursor_type,
        o_alerts             OUT pk_types.cursor_type,
        o_vacc               OUT pk_types.cursor_type,
        o_mcdt               OUT pk_types.cursor_type,
        o_health_program     OUT pk_types.cursor_type,
        o_care_plans         OUT pk_types.cursor_type,
        o_prev_medication    OUT pk_types.cursor_type,
        o_dashboard_tabs     OUT pk_types.cursor_type,
        o_vs                 OUT pk_types.cursor_type,
        o_analysis           OUT pk_types.cursor_type,
        o_diagnosis          OUT pk_types.cursor_type,
        o_assessment_tools   OUT pk_types.cursor_type,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    g_error        VARCHAR2(4000);
    g_sysdate_char VARCHAR2(50);
    g_exception EXCEPTION;

    g_flg_status_f CONSTANT VARCHAR2(1) := 'F'; -- Concluído
    g_flg_status_i CONSTANT VARCHAR2(1) := 'I'; -- Interrompido
    g_flg_status_c CONSTANT VARCHAR2(1) := 'C'; -- Anulado
    g_flg_status_r CONSTANT VARCHAR2(1) := 'R'; -- Requisitado
    g_flg_status_l CONSTANT VARCHAR2(1) := 'L'; -- Lido
    g_flg_status_e CONSTANT VARCHAR2(1) := 'E'; -- Em curso
    g_flg_status_d CONSTANT VARCHAR2(1) := 'D'; -- Pendente
    g_flg_status_t CONSTANT VARCHAR2(1) := 'T'; -- Transporte

    g_flg_time_g CONSTANT VARCHAR2(1) := 'G';

    g_interv_type_nor CONSTANT interv_presc_det.flg_interv_type%TYPE := 'N';
    g_interv_type_sos CONSTANT interv_presc_det.flg_interv_type%TYPE := 'S';
    g_interv_type_uni CONSTANT interv_presc_det.flg_interv_type%TYPE := 'U';
    g_interv_type_ete CONSTANT interv_presc_det.flg_interv_type%TYPE := 'A';

    g_exam_type_img CONSTANT exam.flg_type%TYPE := 'I';
    g_available     CONSTANT VARCHAR2(1) := 'Y';

    g_shortcut_procedures    CONSTANT VARCHAR2(1) := '7';
    g_shortcut_pat_education CONSTANT VARCHAR2(2) := '15';
    g_shortcut_proc_mfr      CONSTANT VARCHAR2(4) := '1659';

    g_package_name  VARCHAR2(200);
    g_package_owner VARCHAR2(200);

    g_presc_nurse_profile     CONSTANT NUMBER(3) := 119;
    g_presc_physician_profile CONSTANT NUMBER(3) := 120;

    g_doc_area_cancer_plan CONSTANT doc_area.id_doc_area%TYPE := 6795;

END pk_patient_summary;
/
