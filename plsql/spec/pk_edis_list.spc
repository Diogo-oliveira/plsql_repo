/*-- Last Change Revision: $Rev: 2028662 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:11 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_edis_list AS

    TYPE rec_transp IS RECORD(
        id_transp_entity NUMBER(24),
        transp_entity    pk_translation.t_desc_translation,
        flg_status       VARCHAR2(1 CHAR),
        rank             NUMBER(6));

    TYPE cursor_transp IS REF CURSOR RETURN rec_transp;

    TYPE table_transp IS TABLE OF rec_transp;

    PROCEDURE open_my_cursor(i_cursor IN OUT cursor_transp);

    /**********************************************************************************************
    * Obter lista de entidades que transportam doentes
    *
    * @param i_lang                   the id language
    * @param i_transp                 Tipo de transporte: A - chegada, D - partida  
    * @param i_prof                   professional, software and institution ids
    * @param o_transp                 cursor with transports entity 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/06/19 
    **********************************************************************************************/
    FUNCTION get_transp_entity_list
    (
        i_lang   IN LANGUAGE.id_language%TYPE,
        i_transp IN transp_entity.flg_transp%TYPE,
        i_prof   IN alert.profissional,
        o_transp OUT cursor_transp,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Obter lista das especialidades das urgências
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_flg_type               Categoria do profissional: S - Assistente social; D - Médico; N - Enfermeiro    
    * @param o_special                cursor with speciality
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/07/20
    **********************************************************************************************/
    FUNCTION get_speciality_list
    (
        i_lang     IN LANGUAGE.id_language%TYPE,
        i_prof     IN alert.profissional,
        i_flg_type IN category.flg_type%TYPE,
        o_special  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Obter lista de todos os profissionais de uma especialidade e que ainda não tenham saída de turno
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_speciality             speciality id     
    * @param i_flg_screen             Identifica qual o ecran onde se realiza a transferência de responsabilidade: 
                                                        OUT - Ecran do Hand Off; IN - Ecran do Hand Off do paciente 
    * @param i_flg_type               Tipo de listagem: A - All: É possível a transferência de responsabilidade para um ou mais profissionais                                               
                                                        S - Single: Só é possível a transferência de responsabilidade para um profissional 
    * @param o_spec_p                 cursor with speciality / professional
    * @param o_flg_type               cursor with types
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/07/20
    **********************************************************************************************/
    FUNCTION get_spec_prof_list
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN alert.profissional,
        i_speciality IN speciality.id_speciality%TYPE,
        i_flg_screen IN VARCHAR2,
        i_flg_type   IN category.flg_type%TYPE,
        o_spec_p     OUT pk_types.cursor_type,
        o_flg_type   OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --

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
    FUNCTION get_prof_cat(i_prof IN alert.profissional) RETURN VARCHAR2;
    --
    /**********************************************************************************************
    * Lista serviços clinicos para filtrar profissionais
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_flg_soft               'Y' is to filtrate by software otherwise 'N'
    * @param o_clin_servs             cursor with clinical services
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/06/30
    **********************************************************************************************/
    FUNCTION get_clin_serv_list
    (
        i_lang       IN NUMBER,
        i_prof       IN alert.profissional,
        i_flg_soft   IN VARCHAR2,
        o_clin_servs OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /**********************************************************************************************
    * Lista profissionais por serviço clinico
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_clin_serv              clinical service department id    
    * @param o_profs                  cursor with professionals
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/06/30
    **********************************************************************************************/
    FUNCTION get_profs_by_clin_serv
    (
        i_lang      IN NUMBER,
        i_prof      IN alert.profissional,
        i_clin_serv IN dep_clin_serv.id_clinical_service%TYPE,
        o_profs     OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Lista profissionais por serviço clinico
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_clin_serv              clinical service department id    
    * @param i_flg_option_none        Show option "None"? (Y) Yes (N) No
    * @param o_profs                  cursor with professionals
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/06/30
    **********************************************************************************************/
    FUNCTION get_profs_by_clin_serv
    (
        i_lang            IN NUMBER,
        i_prof            IN alert.profissional,
        i_clin_serv       IN dep_clin_serv.id_clinical_service%TYPE,
        i_flg_option_none IN VARCHAR2,
        o_profs           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
      Globals
    **/
    g_error VARCHAR2(4000);
    g_exception EXCEPTION;
    g_package_name VARCHAR2(32);

    g_yes CONSTANT VARCHAR2(1) := 'Y';
    g_epis_hand_off_out VARCHAR2(12);
    g_epis_hand_off_in  VARCHAR2(12);
    --
    g_prof_active              CONSTANT professional.flg_state%TYPE := 'A';
    g_prof_cat_doc             CONSTANT category.flg_type%TYPE := 'D';
    g_prof_cat_nrs             CONSTANT category.flg_type%TYPE := 'N';
    g_handoff_nurse_clin_serv  CONSTANT VARCHAR2(2) := 'CS';
    g_handoff_nurse_department CONSTANT VARCHAR2(1) := 'D';

    g_prof_dcs_status_active CONSTANT prof_dep_clin_serv.flg_status%TYPE := 'S';

    g_transp_disch CONSTANT transp_entity.flg_type%TYPE := 'D';
    g_transp_all   CONSTANT transp_entity.flg_type%TYPE := 'A';

    g_flg_profile_type_intern CONSTANT profile_template.flg_type%TYPE := 'I';
END pk_edis_list;
/
