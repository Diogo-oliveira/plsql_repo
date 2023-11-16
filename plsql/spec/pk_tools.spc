/*-- Last Change Revision: $Rev: 2029014 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:18 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_tools AS

    FUNCTION set_dep_clin_serv_hist
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN profissional,
        i_dcs     IN table_number,
        i_flg     IN table_varchar,
        i_dft     IN table_varchar,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_institution
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_department
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_all_service
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dep   IN dept.id_dept%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get professional associated departments for enabled services
    *
    * @param    i_lang                   preferred language id
    * @param    i_prof                   object (id of professional, id of institution, id of software)
    * @param    o_list                   list of departments / services   
    * @param    o_error                  error message
    *
    * @return   boolean: false in case of error, otherwise true
    *
    * @author   Carlos Loureiro
    * @version  1.0
    * @since    2009/09/04
    ********************************************************************************************/
    FUNCTION get_prof_dept_services
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_service
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dep   IN dept.id_dept%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************************************
       OBJECTIVO: Obter listagem dos serviços do departamento seleccionada     
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
             I_PROF - profissional (ID, INSTITUTION, SOFTWARE)  
             I_INST - instituição seleccionada    
          Saída: O_LIST - listagem 
             O_ERROR - erro 
      CRIAÇÃO: CRS 2006/11/11 
      NOTAS: 
    ******************************************************************************************************/

    FUNCTION get_room
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dep   IN department.id_department%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_prof_room
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_room        IN table_number,
        i_room_select IN table_varchar,
        i_room_pref   IN table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_prof_room
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_room  IN table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_prof_room
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_room  IN table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_inst
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_room
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        i_dep   IN department.id_department%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dep_clin_serv
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dep   IN department.id_department%TYPE,
        o_dcs   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_dep_clin_serv
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dcs   IN table_number,
        i_flg   IN table_varchar,
        i_dft   IN table_varchar,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_dep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_inst       IN institution.id_institution%TYPE,
        i_room_cserv IN VARCHAR2,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_soft_lang
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************************************
       OBJECTIVO: Obter aplicações a que o user tem acesso e língua preferencial em cada        
       PARAMETROS: Entrada: I_LANG - Língua registada como preferência do profissional 
            I_PROF - profissional (ID, INSTITUTION, SOFTWARE) 
                            I_INST - Instituição seleccionada 
    
           Saída: O_LIST - lista de departamentos 
                        O_ERROR - erro 
      CRIAÇÃO: CRS 2007/02/13 
      NOTAS: 
    ******************************************************************************************************/

    FUNCTION set_soft_lang
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_lang_selected IN language.id_language%TYPE,
        i_inst          IN institution.id_institution%TYPE,
        i_soft          IN software.id_software%TYPE,
        o_lang          OUT language.id_language%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************************************
       OBJECTIVO: Alterar língua do utilizador     
       PARAMETROS: Entrada: I_LANG - Língua registada como preferência do profissional 
            I_PROF - profissional (ID, INSTITUTION, SOFTWARE) 
                            I_LANG_SELECTED - Língua seleccionada 
                            I_INST - Instituição seleccionada 
                            I_SOFT - Aplicação seleccionada 
    
           Saída: O_LANG - Língua actual, para o utilizador / aplicação / instituição actual 
                        O_ERROR - erro 
      CRIAÇÃO: CRS 2007/02/13 
      NOTAS: 
    ******************************************************************************************************/
    /******************************************************************************************************
       OBJECTIVO: Alternar entre modo de texto e documentation    
       PARAMETROS: Entrada: I_LANG - Língua registada como preferência do profissional 
            I_PROF - profissional (ID, INSTITUTION, SOFTWARE) 
                            I_TYPE - D - Documentation; N - Normal
    
           Saída: O_ERROR - erro 
      CRIAÇÃO: CRS 2007/02/14 
      NOTAS: 
    ******************************************************************************************************/
    FUNCTION set_documentation
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_type  IN VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Nome completo do profissional que requisitou
    *
    * @param i_lang                language id
    * @param i_professional        professional id
    *
    * @return                      description
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       2007/09/24
    **********************************************************************************************/
    FUNCTION get_prof_name
    (
        i_lang         IN language.id_language%TYPE,
        i_professional IN professional.id_professional%TYPE
    ) RETURN VARCHAR2;
    --
    /********************************************************************************************
    * Nome abreviado do profissional que requisitou
    *
    * @param i_lang                language id
    * @param i_professional        professional id
    *
    * @return                      description
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       2007/09/24
    **********************************************************************************************/
    FUNCTION get_prof_nick_name
    (
        i_lang         IN language.id_language%TYPE,
        i_professional IN professional.id_professional%TYPE
    ) RETURN VARCHAR2;
    --
    /********************************************************************************************
    * Especialidade do profissional que requisitou
    *
    * @param i_lang                language id
    * @param i_professional        professional id
    *
    * @return                      description
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       2007/10/10
    **********************************************************************************************/
    FUNCTION get_prof_speciality
    (
        i_lang         IN language.id_language%TYPE,
        i_professional IN professional.id_professional%TYPE
    ) RETURN VARCHAR2;
    --
    /********************************************************************************************
    * Descrição ou abreviatura da instituição
    *
    * @param i_lang                language id
    * @param i_institution         institution id
    * @param i_flg_desc            A - Abreviatura; D - Descrição
    *
    * @return                      description
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       2007/10/10
    **********************************************************************************************/
    FUNCTION get_desc_institution
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_flg_desc    IN VARCHAR2
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Return professional's category.flg_type within institution and software
    *
    * @param i_prof                   professional, software and institution ids
    *
    * @return                         FLG_TYPE from category table
    *                        
    * @author                         João Eiras
    * @version                        1.0 
    * @since                          2007/12/17
    **********************************************************************************************/
    FUNCTION get_prof_cat(i_prof IN profissional) RETURN VARCHAR2;

    /**********************************************************************************************
    * Return professional's PROFILE_TEMPLATE within institution and software
    *
    * @param i_prof                   professional, software and institution ids
    *
    * @return                         ID_PROFILE_TEMPLATE from PROFILE_TEMPLATE table
    *                        
    * @author                         João Eiras
    * @version                        1.0 
    * @since                          2008/04/15
    **********************************************************************************************/
    FUNCTION get_prof_profile_template(i_prof IN profissional) RETURN profile_template.id_profile_template%TYPE;

    /********************************************************************************************
    * Professional description ready to be presented in reports
    *
    * @param i_lang                language id
    * @param i_prof                professional
    * @param i_prof_id             professional id who wrote the data
    * @param i_date                Date (timestamp)
    * @param i_episode             Episode ID
    *
    * @return                      Professional description, with name and specialty, if any is defined
    *    
    * @author                      João Taborda
    * @version                     1.0
    * @since                       2008/ABR/15
    *
    * UPDATED
    * ALERT-10363 - Alteração do nome do profissional e especialidade do Timestamp
    * @author  Jose Antunes
    * @version 2.5
    * @date    10-03-2009
    **********************************************************************************************/
    FUNCTION get_prof_description
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_prof_id IN professional.id_professional%TYPE,
        i_date    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Professional description ready to be presented in reports paramedical professional:
    * Professional name (Institution Abr)
    *
    * @param i_lang                language id
    * @param i_prof                professional
    * @param i_prof_id             professional id who wrote the data
    * @param i_date                Date (timestamp)
    * @param i_episode             Episode ID
    *
    * @return                      Professional description, with name and specialty, if any is defined
    *    
    * @author                      Sofia Mendes
    * @version                     2.6.0.3
    * @since                       13-Jul-2010
    *    
    **********************************************************************************************/
    FUNCTION get_prof_description_cat
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_prof_id IN professional.id_professional%TYPE,
        i_date    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Check the availability of a professional into a software for Exams and Analysis 
    *
    * @param       i_lang                    Professional preferred language
    * @param       i_id_professional         Professional identifier
    * @param       i_id_institution          Institution identifier
    * @param       i_flg_soft_context        Flag to check when analysis or exams
    * @param       o_prof_valid              Flag that returns if the professional is valid or not to the related context
    * @param       o_id_software             The software identifier for the related context where the professional has permissions
    * @param       o_message                 Error message
    *
    * @return                                true on success, otherwise false
    *
    * @value       i_flg_soft_context        {*} 'ANA'- ANALYSIS {*} 'EXA'- EXAMS
    * @value       o_prof_valid              {*} 'Y'- VALID {*} 'N'- NOT VALID
    *
    * @author                                António Neto
    * @version                               2.6.2.0.5
    * @since                                 09-Jan-2011
    **********************************************************************************************/
    FUNCTION get_prof_software
    (
        i_lang             IN language.id_language%TYPE,
        i_id_professional  IN professional.id_professional%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_flg_soft_context IN VARCHAR2,
        o_prof_valid       OUT VARCHAR2,
        o_id_software      OUT NUMBER,
        o_message          OUT VARCHAR2
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get all institution clinical services.
    *
    * @param    i_lang                   preferred language id
    * @param    i_prof                   object (id of professional, id of institution, id of software)
    * @param    i_institution            institution id  
    *
    * @return   table_number that contains all clinical services identifiers
    *
    * @author   Gisela Couto
    * @version  2.6.4.1.1
    * @since    2014/08/27
    ********************************************************************************************/
    FUNCTION get_inst_clin_serv_ids
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE
    ) RETURN table_number;

    /********************************************************************************************
    * Get all institution clinical services.
    *
    * @param    i_lang                   preferred language id
    * @param    i_prof                   object (id of professional, id of institution, id of software)
    * @param    i_institution            institution id  
    *
    * @return   table_varchar that contains all clinical services codes
    *
    * @author   Gisela Couto
    * @version  2.6.4.1.1
    * @since    2014/08/27
    ********************************************************************************************/
    FUNCTION get_inst_clin_serv_codes
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE
    ) RETURN table_varchar;

    /**
      Globais
    **/
    g_exception EXCEPTION;

    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_error        VARCHAR2(2000);
    g_found        BOOLEAN;
    g_no CONSTANT VARCHAR2(1) := 'N';

    g_prof_room_npref CONSTANT prof_room.flg_pref%TYPE := 'N';
    g_prof_room_pref  CONSTANT prof_room.flg_pref%TYPE := 'Y';

    g_flg_available CONSTANT VARCHAR2(1) := 'Y';
    g_selected      CONSTANT VARCHAR2(1) := 'S';
    g_status_pdcs_s CONSTANT prof_dep_clin_serv.flg_status%TYPE := 'S';

    g_dep_cons_cli CONSTANT department.flg_type%TYPE := 'CL';
    g_dep_cons_ext CONSTANT department.flg_type%TYPE := 'CE';
    g_dep_cons_pri CONSTANT department.flg_type%TYPE := 'CP';
    g_dep_ed       CONSTANT department.flg_type%TYPE := 'U';
    g_dep_imag     CONSTANT department.flg_type%TYPE := 'I';
    g_dep_inp      CONSTANT department.flg_type%TYPE := 'I';
    g_dep_lab      CONSTANT department.flg_type%TYPE := 'A';
    g_dep_or       CONSTANT department.flg_type%TYPE := 'S';
    g_dep_pharm    CONSTANT department.flg_type%TYPE := 'F';

    g_config_document_text CONSTANT sys_config.id_sys_config%TYPE := 'DOCUMENTATION_TEXT';
    g_config_documentation CONSTANT sys_config.id_sys_config%TYPE := 'DOCUMENTATION_INST';
    g_domain_template      CONSTANT sys_domain.code_domain%TYPE := 'TEMPLATE_TEXT';

    g_abbreviation CONSTANT institution.abbreviation%TYPE := 'A';

END pk_tools;
/
