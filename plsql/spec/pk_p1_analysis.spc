/*-- Last Change Revision: $Rev: 2028828 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:11 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_p1_analysis AS

    /****************************************************************************************
    PROJECT         : ALERT-P1 
    PROJECT TEAM    : JOAO SA ( TEAM LEADER, PROJECT ANALYSIS, JAVA MAN ), 
                      CARLOS FERREIRA ( PROJECT ANALYSIS, DB MAN ), 
                      RUI DIAS ( PROJECT ANALYSIS, FLASH MAN ).
    
    PK CREATED BY   : CARLOS FERREIRA
    PK DATE CREATION: 07-2005
    PK GOAL         : THIS PACKAGE TAKES CARE OF ALL FUNCTIONS THE ANALYSIS REQUEST 
    
    NOTES/ OBS      : ---
    ******************************************************************************************/

    /**
    * Get analysis from analysis group.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ANALALYSIS_GROUP id analysis group
    * @param   I_PROF_CAT_TYPE  type of professional category
    * @param   O_ANALYSIS analysis list
    * @param   O_ERROR an error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  CRS 
    * @version 2.4.3
    * @since   2005-12-14
    * @modify  Joao Sa 2008-04-14 pode usar funcao de pk_analysis. As analises do grupo nao dependem da instituicao.
    */

    FUNCTION get_lab_test_in_group
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_analysis_group IN analysis_group.id_analysis_group%TYPE,
        i_codification   IN codification.id_codification%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get sample type list
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_PATIENT selected patient
    * @param   O_SAMPLE_TYPE flag sample type list
    * @param   O_ERROR an error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 2.4.3
    * @since   27-02-2008
    */

    FUNCTION get_sample_type_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        o_sample_type OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get institutions for the selected analysis
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ANALYSIS selected analysis
    * @param   O_INST_DEST destination institution
    * @param   O_REF_AREA flag to reference area
    * @param   O_ERROR an error message, set when return=false
    *
    * @value   O_REF_AREA {*} 'Y' in reference area {*} 'N' out of reference area
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 2.4.3
    * @since   22-02-2008
    * @modify Joana Barroso 08/05/2008 JOIN
    */

    FUNCTION get_analysis_institutions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_analysis     IN analysis.id_analysis%TYPE,
        o_institutions OUT pk_types.cursor_type,
        o_ref_area     OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get referral analysis
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   i_ext_req referral id
    * @param   o_analysis  analysis list
    * @param   O_ERROR an error message, set when return=false
    *
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 2.4.3
    * @since   26-02-2008
    * @modify  Joana Barroso 8-03-2008 estava errado di.id_dest_institution
    * @modify Joana Barroso 08/05/2008 JOIN
    */
    /*
        FUNCTION get_ext_req_analysis
        (
            i_lang     IN LANGUAGE.id_language%TYPE,
            i_prof     IN profissional,
            i_ext_req  IN NUMBER,
            o_analysis OUT pk_types.cursor_type,
            o_error    OUT VARCHAR2
        ) RETURN BOOLEAN;
    */
    /**
    * Get default institutions for the selected analysis
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ANALYSIS selected analysis
    * @param   O_INST_DEST default destination institution
    * @param   O_REF_AREA flag to reference area
    * @param   O_ERROR an error message, set when return=false
    *
    * @value   O_REF_AREA {*} 'Y' in reference area {*} 'N' out of reference area
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 2.4.3
    * @since   26-02-2008
    * @modify Joana Barroso 08/05/2008 JOIN
    */
    -- Versão 2.4.3: Nao tem coluna p1_dest_institution.flg_inside_ref_area
    FUNCTION get_analysis_default_insts
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_analysis     IN table_number,
        o_institutions OUT pk_types.cursor_type,
        o_ref_area     OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get common institution based on all required analysis
    *
    * @param    i_lang            preferred language id
    * @param    i_prof            object (id of professional, id of institution, id of software)
    * @param    i_analysis        array of requested analysis
    * @param    o_inst            cursor with institution information
    * @param    o_error           error message structure
    *
    * @return   boolean           false in case of error, otherwise true
    *
    * @author   Carlos Loureiro
    * @version  1.0
    * @since    2009/08/28
    ********************************************************************************************/
    FUNCTION get_analysis_inst
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_analysis IN table_number,
        o_inst     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_analysis_inst
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_analysis IN VARCHAR2
    ) RETURN t_tbl_core_domain;    

    /**
    * Checks if referral can be sent to dest institution: all analysis req are ready to be sent
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Id professional, institution and software    
    * @param   i_analysis_req_det    Analysis req detail identification    
    * @param   o_flg_completed       Flag indicating if all analysis workflow are completed in professionl institution
    * @param   O_ERROR               An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   31-08-2009
    */
    FUNCTION check_ref_completed
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        o_flg_completed    OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_ref_analysis_req_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        o_sql              OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    --xsp VARCHAR2(0050); -- CHARACTER "SPACE"
    --xpl VARCHAR2(0050); -- CHARACTER '

    pk_p1_lang         VARCHAR2(0050); -- PACKAGE VAR FOR CURRENT LANGUAGE USED
    pk_p1_nls_language VARCHAR2(0050); -- PACKAGE VAR FOR NLLS_LANGUAGE STRING

    xerr    VARCHAR2(4000); -- VAR FOR MISCELANIOUS STORING
    l_ret   BOOLEAN; -- VAR FOR BOOLEAN VALUES RETURNED BY AUXILIARY FUNCTIONS
    g_error VARCHAR2(4000);

    g_selected CONSTANT VARCHAR2(1) := 'S';

    g_exception EXCEPTION;
    g_package_name VARCHAR2(30) := 'PK_P1_ANALYSIS';
    g_package_owner     CONSTANT VARCHAR2(50) := 'ALERT';
    g_ref_external_inst CONSTANT sys_config.id_sys_config%TYPE := 'REF_EXTERNAL_INST';
    g_retval BOOLEAN;

END pk_p1_analysis;
/
