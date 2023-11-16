/*-- Last Change Revision: $Rev: 2028615 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:55 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_documentation AS

    FUNCTION set_epis_complaint
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis              IN episode.id_episode%TYPE,
        i_complaint         IN complaint.id_complaint%TYPE,
        i_patient_complaint IN epis_complaint.patient_complaint%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_complaint
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis      IN episode.id_episode%TYPE,
        o_complaint OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_complaint_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis      IN episode.id_episode%TYPE,
        o_complaint OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_complain_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis              IN episode.id_episode%TYPE,
        i_epis_complaint    IN epis_complaint.id_epis_complaint%TYPE,
        o_complaint         OUT pk_types.cursor_type,
        o_patient_complaint OUT pk_types.cursor_type,
        o_historian         OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_notes
    (
        i_lang          IN language.id_language%TYPE,
        i_epis          IN episode.id_episode%TYPE,
        i_id_pat        IN identification_notes.id_patient%TYPE,
        i_prof          IN profissional,
        i_notes         IN identification_notes.notes%TYPE,
        i_document_area IN doc_area.id_doc_area%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_notes
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_id_pat        IN identification_notes.id_patient%TYPE,
        i_document_area IN doc_area.id_doc_area%TYPE,
        o_notes         OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_component_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_epis              IN episode.id_episode%TYPE,
        o_id_epis_bartchart OUT epis_documentation.id_epis_documentation%TYPE,
        o_epis_complaint    OUT pk_types.cursor_type,
        o_id_epis_complaint OUT epis_complaint.id_epis_complaint%TYPE,
        o_component         OUT pk_types.cursor_type,
        o_element           OUT pk_types.cursor_type,
        o_elemnt_status     OUT pk_types.cursor_type,
        o_elemnt_action     OUT pk_types.cursor_type,
        o_element_exclusive OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_component_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_epis              IN episode.id_episode%TYPE,
        i_interv            IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        o_id_epis_bartchart OUT epis_documentation.id_epis_documentation%TYPE,
        o_epis_complaint    OUT pk_types.cursor_type,
        o_id_epis_complaint OUT epis_complaint.id_epis_complaint%TYPE,
        o_component         OUT pk_types.cursor_type,
        o_element           OUT pk_types.cursor_type,
        o_elemnt_status     OUT pk_types.cursor_type,
        o_elemnt_action     OUT pk_types.cursor_type,
        o_element_exclusive OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_triage_color
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis              IN episode.id_episode%TYPE,
        o_epis_triage_color OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_element_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_sys_docum IN documentation.id_documentation%TYPE,
        o_element   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_epis_bartchart
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_epis                 IN episode.id_episode%TYPE,
        i_document_area        IN doc_area.id_doc_area%TYPE,
        i_epis_complaint       IN epis_complaint.id_epis_complaint%TYPE,
        i_id_sys_documentation IN table_number,
        i_id_sys_element       IN table_number,
        i_id_sys_element_crit  IN table_number,
        i_value                IN table_varchar,
        i_notes                IN epis_documentation_det.notes%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_epis_bartchart
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_epis                  IN episode.id_episode%TYPE,
        i_document_area         IN doc_area.id_doc_area%TYPE,
        i_epis_complaint        IN epis_complaint.id_epis_complaint%TYPE,
        i_id_sys_documentation  IN table_number,
        i_id_sys_element        IN table_number,
        i_id_sys_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation_det.notes%TYPE,
        i_commit                IN VARCHAR2,
        o_id_epis_documentation OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_bartchart
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_epis              IN episode.id_episode%TYPE,
        o_last_update       OUT pk_types.cursor_type,
        o_epis_triage_color OUT pk_types.cursor_type,
        o_epis_bartchart    OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_bartchart
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_epis              IN episode.id_episode%TYPE,
        i_interv            IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        o_last_update       OUT pk_types.cursor_type,
        o_epis_triage_color OUT pk_types.cursor_type,
        o_epis_bartchart    OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_bartchart_comp
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_doc_area             IN doc_area.id_doc_area%TYPE,
        i_epis                 IN episode.id_episode%TYPE,
        i_flg_show             IN VARCHAR2,
        i_id_sys_documentation IN documentation.id_documentation%TYPE,
        i_id_epis_bartchart    IN epis_documentation.id_epis_documentation%TYPE,
        o_epis_bartchart_comp  OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION sr_set_epis_documentation
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_epis                IN episode.id_episode%TYPE,
        i_episode_context     IN episode.id_episode%TYPE,
        i_epis_documentation  IN epis_documentation.id_epis_documentation%TYPE,
        i_doc_area            IN doc_area.id_doc_area%TYPE,
        i_epis_complaint      IN epis_complaint.id_epis_complaint%TYPE,
        i_id_documentation    IN table_number,
        i_id_doc_element      IN table_number,
        i_id_doc_element_crit IN table_number,
        i_value               IN table_varchar,
        i_notes               IN epis_documentation_det.notes%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:Permite registar uma nova avaliação para o episódio ou registar novos registos sobre 
                 uma já existente e respectivas notas.
                    
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                             I_PROF - ID do profissional
                     I_EPIS  - ID do episódio
                             I_EPIS_DOCUMENTATION - ID da visita. Se não estiver preenchido cria uma nova
                             I_DOC_AREA - Area da aplicação onde é feito o registo
                             I_EPIS_COMPLAINT - ID do registo na epis_complait activo no momento  
                                                                         
                             I_ID_DOCUMENTATION   - ID do DOCUMENTATION 
                             I_ID_DOC_ELEMENT- ID do DOC_ELEMENT
                             I_ID_DOC_ELEMENT_CRIT     - ID do DOC_ELEMENT_CRIT
                             I_VALUE   - Array com os valores de cada elemento (quando exite um registo de hora, numero ou texto)
                             I_NOTES   - Notas associadas a uma DOC_AREA 
                            
           Saida: O_ERROR - Erro 
      
     CRIAÇÃO: RB 2006/10/23
      NOTAS: 
    *********************************************************************************/

    FUNCTION sr_get_epis_documentation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_epis               IN episode.id_episode%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_last_update        OUT pk_types.cursor_type,
        o_epis_triage_color  OUT pk_types.cursor_type,
        o_epis_doc           OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Permite registar uma nova  BARTCHART para o episódio ou registar novos registos sobre 
          uma já existente e respectivas notas.
                    
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                             I_PROF - ID do profissional
                             I_DOC_AREA - Area da aplicação onde é feito o registo
                     I_EPIS  - ID do episódio
                             I_EPIS_DOCUMENTATION - ID da visita. Se não estiver preenchido cria uma nova
                                                                                                                                                   
           Saida: O_LAST_UPDATE   -  informação de quem e quando fez a ultima actualização na bartchart
                             O_EPIS_TRIAGE_COLOR - Cor de triagem actribuida ao episódio 
                             O_EPIS_BARTCHART  - ultimo registo da chart
                             O_ERROR - Erro 
      
     CRIAÇÃO: SF 2006/10/08
      NOTAS: 
    *********************************************************************************/

    FUNCTION sr_get_epis_documentation_comp
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_doc_area                IN doc_area.id_doc_area%TYPE,
        i_epis                    IN episode.id_episode%TYPE,
        i_flg_show                IN VARCHAR2,
        i_id_documentation        IN documentation.id_documentation%TYPE,
        i_id_epis_documentation   IN epis_documentation.id_epis_documentation%TYPE,
        o_epis_documentation_comp OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO: Permite registar uma nova  BARTCHART para o episódio ou registar novos registos sobre 
                  uma já existente e respectivas notas.
                    
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                             I_PROF - ID do profissional
                     I_EPIS  - ID do episódio
                             I_DOC_AREA - Area da aplicação onde é feito o registo
                             I_BARTCHART 
                             I_SHOW -  modo de visualização                                                                     
                             I_SYS_DOCUMENTATION - componente para o qual quer ver registos
                            
                      Saida: EPIS_DOCUMENTATION_COMP -  ultimo registo mediate o modo de visualização 
                             O_ERROR - Erro 
      
     CRIAÇÃO: RB 2006/10/08
      NOTAS: 
    *********************************************************************************/

    FUNCTION sr_cancel_epis_documentation
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_id_epis_doc IN epis_documentation.id_epis_documentation%TYPE,
        i_notes       IN VARCHAR2,
        i_test        IN VARCHAR2,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg_text    OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Cancela uma avaliação
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                             I_PROF - ID do profissional q regista
                             I_EPIS - ID do episódio
                             I_ID_EPIS_DOC - ID da avaliação a cancelar
                             I_NOTES - Notas de cancelamento
                             I_TEST - Indica se deve mostrar a confirmação de alteração
                    
                    Saida: O_FLG_SHOW - indica se deve ser mostrada uma mensagem (Y / N) 
               O_MSG_TITLE - Título da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y 
               O_MSG_TEXT - Texto da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y 
               O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado 
                           O_ERROR - erro 
     
      CRIAÇÃO: RB 2006/10/29
      NOTAS: 
    *********************************************************************************/

    FUNCTION sr_get_component_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        o_id_epis_documentation OUT epis_documentation.id_epis_documentation%TYPE,
        o_component             OUT pk_types.cursor_type,
        o_element               OUT pk_types.cursor_type,
        o_elemnt_status         OUT pk_types.cursor_type,
        o_elemnt_action         OUT pk_types.cursor_type,
        o_element_exclusive     OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Listar os componentes associados a uma área 
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                    I_PROF - ID do profissional
                             I_DOC_AREA- ID da área
                             I_EPIS - ID do episódio
                             O_ID_EPIS_DOCUMENTATION - Registo na EPIS_DOCUMENTATION para o episódio
                             
           Saida: O_ID_EPIS_COMPLAINT 
                             O_COMPONENT - Listar os componentes associados a uma área
                             O_ELEMENT - Listar os elementos associados aos componentes de uma àrea
                             O_ELEMNT_STATUS - Listar os estados possiveis para os elementos associados aos componentes de uma àrea
                             O_ELEMNT_ACTION - Listar as accções de elementos sobre outros elementos associados aos componentes de uma àrea                        O_ERROR - erro 
     
      CRIAÇÃO: SF 2006/10/02
      NOTAS: 
    *********************************************************************************/

    FUNCTION sr_set_notes
    (
        i_lang     IN language.id_language%TYPE,
        i_epis     IN episode.id_episode%TYPE,
        i_id_pat   IN identification_notes.id_patient%TYPE,
        i_prof     IN profissional,
        i_notes    IN identification_notes.notes%TYPE,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Registar as notas do paciente por episódio/ paciente
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                             I_EPIS - ID do episódio
                    I_ID_PAT - ID do paciente
                I_PROF - ID do profissional
                I_NOTES - Notas 
                            I_DOC_AREA - Área do documentation
                             
           Saida: O_ERROR - erro 
     
      CRIAÇÃO: ET 2006/08/09
      NOTAS: 
    *********************************************************************************/

    FUNCTION sr_get_notes
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_epis     IN episode.id_episode%TYPE,
        i_id_pat   IN identification_notes.id_patient%TYPE,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        o_notes    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Listar as notas do paciente
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                    I_PROF - ID do profissional
                             I_EPIS - ID do episódio
                     I_ID_PAT - ID do paciente
                             I_DOCUMENT_AREA - Área do documentation
                             
           Saida: O_NOTES - Listar as notas associadas ao apciente / episódio
                             O_ERROR - erro 
     
      CRIAÇÃO: ET 2006/08/10
      NOTAS: 
    *********************************************************************************/

    FUNCTION sr_get_element_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_sys_docum IN documentation.id_documentation%TYPE,
        o_element   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Listar os elementos associados a um componente
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                   I_PROF - ID do profissional
                             I_SYS_DOCUM - ID da relação componente/ area
                             
                      Saida: O_ELEMENT - Listar os elementos associados a um componente
                             O_ERROR - erro 
     
      CRIAÇÃO: ET 2006/08/10
      NOTAS: 
    *********************************************************************************/

    FUNCTION sr_get_doc_template
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_doc_type     IN documentation_type.id_documentation_type%TYPE,
        o_doc_template OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Listar todos os templates
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                             I_PROF - ID do profissional q regista
                             I_DOC_TYPE - ID do tipo de documentation
                             
              Saida: O_DOC_TEMPLATE - Listar todos os templates
                             O_ERROR - erro
    
      CRIAÇÃO: ET 2006/11/07
      NOTAS:  
    *********************************************************************************/

    FUNCTION sr_get_doc_area
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_doc_area OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Listar as áreas disponiveis para a documentation
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                             I_PROF - ID do profissional q regista
                             
              Saida: O_DOC_AREA - Listar as áreas disponiveis para a documentation
                             O_ERROR - erro
    
      CRIAÇÃO: ET 2006/11/07
      NOTAS:  
    *********************************************************************************/

    FUNCTION sr_get_documentation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_doc_area      IN doc_area.id_doc_area%TYPE,
        i_doc_template  IN doc_template.id_doc_template%TYPE,
        o_documentation OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Listar todos os componentes associados a uma área e a um template
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                             I_PROF - ID do profissional q regista
                             I_DOC_AREA - ID da área seleccionada
                             I_DOC_TEMPLATE - ID do template seleccionado
                             
              Saida: O_DOCUMENTATION - Listar todos os componentes associados a uma área e a um template
                             O_ERROR - erro
    
      CRIAÇÃO: ET 2006/11/07
      NOTAS:  
    *********************************************************************************/

    FUNCTION sr_get_doc_dimension
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_doc_dimension OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Listar as possiveis dimensões a serem atribuidas aos diferentes componentes
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                             I_PROF - ID do profissional q regista
                             
              Saida: O_DOC_DIMENSION - Listar as possiveis dimensões a serem atribuidas aos diferentes componentes
                             O_ERROR - erro
    
      CRIAÇÃO: ET 2006/11/07
      NOTAS:  
    *********************************************************************************/

    FUNCTION sr_get_doc_element
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_documentation IN documentation.id_documentation%TYPE,
        o_doc_element   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Listar os elementos associados a um documentation (componente)
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                             I_PROF - ID do profissional q regista
                             I_DOCUMENTATION - ID da documentation
                             
              Saida: O_DOC_ELEMENT - Listar os elementos associados a um documentation (componente)
                             O_ERROR - erro
    
      CRIAÇÃO: ET 2006/11/07
      NOTAS:  
    *********************************************************************************/

    FUNCTION get_templ_component_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        o_id_epis_documentation OUT epis_documentation.id_epis_documentation%TYPE,
        o_component             OUT pk_types.cursor_type,
        o_element               OUT pk_types.cursor_type,
        o_elemnt_status         OUT pk_types.cursor_type,
        o_elemnt_action         OUT pk_types.cursor_type,
        o_element_exclusive     OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get current state of HPI for viewer checlist 
    *             
    * @param    i_lang          Language ID
    * @param    i_prof          Logged professional structure
    * @param    i_scope_type    Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode    Episode ID
    * @param    i_id_patient    Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_hpi
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    *  Get current state of Reiew of system for viewer checlist 
    *             
    * @param    i_lang          Language ID
    * @param    i_prof          Logged professional structure
    * @param    i_scope_type    Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode    Episode ID
    * @param    i_id_patient    Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_review_sys
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;
    --

    /********************************************************************************************
    *  Get current state of family history for viewer checlist 
    *             
    * @param    i_lang          Language ID
    * @param    i_prof          Logged professional structure
    * @param    i_scope_type    Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode    Episode ID
    * @param    i_id_patient    Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_family_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    *  Get current state of social history for viewer checlist 
    *             
    * @param    i_lang          Language ID
    * @param    i_prof          Logged professional structure
    * @param    i_scope_type    Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode    Episode ID
    * @param    i_id_patient    Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_social_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    *  Get current state of Physical exam for viewer checlist 
    *             
    * @param    i_lang          Language ID
    * @param    i_prof          Logged professional structure
    * @param    i_scope_type    Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode    Episode ID
    * @param    i_id_patient    Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_physical_exam
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    *  Get current state of Plan for viewer checlist 
    *             
    * @param    i_lang          Language ID
    * @param    i_prof          Logged professional structure
    * @param    i_scope_type    Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode    Episode ID
    * @param    i_id_patient    Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_plan
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /* *******************************************************************************************
    *  Get current state of medico legista for viewer checlist 
    *             
    * @param    i_lang          Language ID
    * @param    i_prof          Logged professional structure
    * @param    i_scope_type    Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode    Episode ID
    * @param    i_id_patient    Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_medic_legist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    --
    --
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);
    g_error         VARCHAR2(4000);
    g_exception EXCEPTION;
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;
    g_available       CONSTANT complaint.flg_available%TYPE := 'Y';
    g_flg_status      CONSTANT episode.flg_status%TYPE := 'A';
    g_complaint_act   CONSTANT epis_complaint.flg_status%TYPE := 'A';
    g_complaint_inact CONSTANT epis_complaint.flg_status%TYPE := 'I';

    g_default    CONSTANT doc_element_crit.flg_default%TYPE := 'Y';
    g_default_no CONSTANT doc_element_crit.flg_default%TYPE := 'N';
    --
    g_flg_show CONSTANT triage_color.flg_show%TYPE := 'Y';

    g_position_in  CONSTANT VARCHAR2(1) := 'I';
    g_position_out CONSTANT VARCHAR2(1) := 'O';
    --
    g_position_desc_out CONSTANT VARCHAR2(3) := 'OUT';
    g_position_desc_in  CONSTANT VARCHAR2(2) := 'IN';
    --

    g_criteria CONSTANT VARCHAR2(1) := 'I';

    g_epis_bartchart_act     CONSTANT epis_bartchart.flg_status%TYPE := 'A';
    g_epis_documentation_act CONSTANT epis_documentation.flg_status%TYPE := 'A';
    g_value_doc_type_default CONSTANT documentation.value_document_type%TYPE := 1;

    g_flg_workflow CONSTANT documentation_rel.flg_action%TYPE := 'W';

    g_cancel        CONSTANT VARCHAR2(1) := 'C';
    g_active        CONSTANT VARCHAR2(1) := 'A';
    g_flg_mandatory CONSTANT VARCHAR2(1) := 'Y';
    g_value_y       CONSTANT VARCHAR2(1) := 'Y';
    g_value_n       CONSTANT VARCHAR2(1) := 'N';
    --
    g_flg_type_c CONSTANT VARCHAR2(1) := 'C';

    g_comp_filter_prf CONSTANT VARCHAR2(4000) := 'PROFILE_TEMPLATE';
    g_comp_filter_dcs CONSTANT VARCHAR2(4000) := 'DEP_CLIN_SERV';

END pk_documentation;
/
