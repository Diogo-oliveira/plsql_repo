/*-- Last Change Revision: $Rev: 2029047 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:29 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_wf_referral IS

    -- Author  : FILIPE.SOUSA
    -- Created : 14-09-2010 16:56:54
    -- Purpose : 

    -- Public type declarations
    --TYPE <TypeName> IS <Datatype>;

    -- Public constant declarations
    -- <ConstantName> CONSTANT <Datatype> := <Value>;

    -- Public variable declarations
    -- <VariableName> <Datatype>;

    -- Public function and procedure declarations
    /**
    * <Function description>
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   14-09-2010
    */
    PROCEDURE add_all_for_transition
    (
        i_lang                 IN LANGUAGE.id_language%TYPE,
        tc_id_workflow         IN wf_workflow.id_workflow%TYPE DEFAULT NULL,
        tc_id_status_begin     IN wf_status.id_status%TYPE DEFAULT NULL,
        tc_id_status_end       IN wf_status.id_status%TYPE DEFAULT NULL,
        tc_id_software         IN software.id_software%TYPE DEFAULT NULL,
        tc_id_institution      IN institution.id_institution%TYPE DEFAULT NULL,
        tc_id_profile_template IN profile_template.id_profile_template%TYPE DEFAULT NULL,
        tc_id_functionality    IN sys_functionality.id_functionality%TYPE DEFAULT NULL,
        tc_function            IN wf_transition_config.FUNCTION%TYPE DEFAULT NULL,
        tc_rank                IN wf_transition_config.rank%TYPE DEFAULT NULL,
        tc_flg_permission      IN wf_transition_config.flg_permission%TYPE DEFAULT NULL,
        tc_id_category         IN category.id_category%TYPE DEFAULT NULL,
        t_flg_available        IN wf_transition.flg_available%TYPE DEFAULT NULL,
        sc_b_icon              IN wf_status_config.icon%TYPE DEFAULT NULL,
        sc_b_color             IN wf_status_config.color%TYPE DEFAULT NULL,
        sc_b_rank              IN wf_status_config.rank%TYPE DEFAULT NULL,
        sc_b_function          IN wf_status_config.FUNCTION%TYPE DEFAULT NULL,
        sc_b_flg_insert        IN wf_status_config.flg_insert%TYPE DEFAULT NULL,
        sc_b_flg_update        IN wf_status_config.flg_update%TYPE DEFAULT NULL,
        sc_b_flg_delete        IN wf_status_config.flg_delete%TYPE DEFAULT NULL,
        sc_b_flg_read          IN wf_status_config.flg_read%TYPE DEFAULT NULL,
        s_b_description        IN wf_status.description%TYPE DEFAULT NULL,
        s_b_icon               IN wf_status.icon%TYPE DEFAULT NULL,
        s_b_color              IN wf_status.color%TYPE DEFAULT NULL,
        s_b_rank               IN wf_status.rank%TYPE DEFAULT NULL,
        s_b_flg_available      IN wf_status.flg_available%TYPE DEFAULT NULL,
        sw_b_description       IN wf_status_workflow.description%TYPE DEFAULT NULL,
        sw_b_flg_begin         IN wf_status_workflow.flg_begin%TYPE DEFAULT NULL,
        sw_b_flg_final         IN wf_status_workflow.flg_final%TYPE DEFAULT NULL,
        sw_b_flg_available     IN wf_status_workflow.flg_available%TYPE DEFAULT NULL,
        sc_e_icon              IN wf_status_config.icon%TYPE DEFAULT NULL,
        sc_e_color             IN wf_status_config.color%TYPE DEFAULT NULL,
        sc_e_rank              IN wf_status_config.rank%TYPE DEFAULT NULL,
        sc_e_function          IN wf_status_config.FUNCTION%TYPE DEFAULT NULL,
        sc_e_flg_insert        IN wf_status_config.flg_insert%TYPE DEFAULT NULL,
        sc_e_flg_update        IN wf_status_config.flg_update%TYPE DEFAULT NULL,
        sc_e_flg_delete        IN wf_status_config.flg_delete%TYPE DEFAULT NULL,
        sc_e_flg_read          IN wf_status_config.flg_read%TYPE DEFAULT NULL,
        s_e_description        IN wf_status.description%TYPE DEFAULT NULL,
        s_e_icon               IN wf_status.icon%TYPE DEFAULT NULL,
        s_e_color              IN wf_status.color%TYPE DEFAULT NULL,
        s_e_rank               IN wf_status.rank%TYPE DEFAULT NULL,
        s_e_flg_available      IN wf_status.flg_available%TYPE DEFAULT NULL,
        sw_e_description       IN wf_status_workflow.description%TYPE DEFAULT NULL,
        sw_e_flg_begin         IN wf_status_workflow.flg_begin%TYPE DEFAULT NULL,
        sw_e_flg_final         IN wf_status_workflow.flg_final%TYPE DEFAULT NULL,
        sw_e_flg_available     IN wf_status_workflow.flg_available%TYPE DEFAULT NULL,
        wm_id_market           IN wf_workflow_market.id_market%TYPE DEFAULT NULL,
        ws_flg_available       IN wf_workflow_software.flg_available%TYPE DEFAULT NULL,
        w_internal_name        IN wf_workflow.internal_name%TYPE DEFAULT NULL,
        w_description          IN wf_workflow.description%TYPE DEFAULT NULL,
        print_translation_cod  IN BOOLEAN := FALSE
        
    );

    /**
    * <Function description>
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   14-09-2010
    */
    PROCEDURE add_all_for_status
    (
        i_lang                 IN LANGUAGE.id_language%TYPE,
        sc_id_workflow         IN wf_workflow.id_workflow%TYPE,
        sc_id_status           IN wf_status.id_status%TYPE,
        sc_id_software         IN software.id_software%TYPE,
        sc_id_institution      IN institution.id_institution%TYPE,
        sc_id_profile_template IN profile_template.id_profile_template%TYPE,
        sc_id_functionality    IN sys_functionality.id_functionality%TYPE,
        sc_id_category         IN category.id_category%TYPE,
        sc_icon                IN wf_status_config.icon%TYPE,
        sc_color               IN wf_status_config.color%TYPE,
        sc_rank                IN wf_status_config.rank%TYPE,
        sc_function            IN wf_status_config.FUNCTION%TYPE DEFAULT NULL,
        sc_flg_insert          IN wf_status_config.flg_insert%TYPE,
        sc_flg_update          IN wf_status_config.flg_update%TYPE,
        sc_flg_delete          IN wf_status_config.flg_delete%TYPE,
        sc_flg_read            IN wf_status_config.flg_read%TYPE,
        s_description          IN wf_status.description%TYPE DEFAULT NULL,
        s_icon                 IN wf_status.icon%TYPE DEFAULT NULL,
        s_color                IN wf_status.color%TYPE DEFAULT NULL,
        s_rank                 IN wf_status.rank%TYPE DEFAULT NULL,
        s_flg_available        IN wf_status.flg_available%TYPE DEFAULT 'Y',
        sw_description        IN wf_status_workflow.description%TYPE DEFAULT NULL,
        sw_flg_begin          IN wf_status_workflow.flg_begin%TYPE DEFAULT 'Y',
        sw_flg_final          IN wf_status_workflow.flg_final%TYPE DEFAULT 'Y',
        sw_flg_available      IN wf_status_workflow.flg_available%TYPE DEFAULT 'Y',
        wm_id_market           IN wf_workflow_market.id_market%TYPE DEFAULT 0,
        ws_id_software        IN software.id_software%TYPE DEFAULT NULL,
        ws_flg_available      IN wf_workflow_software.flg_available%TYPE DEFAULT NULL,
        w_internal_name       IN wf_workflow.internal_name%TYPE DEFAULT NULL,
        w_description         IN wf_workflow.description%TYPE DEFAULT NULL,
        print_translation_cod IN BOOLEAN := FALSE
        
    );

    /**
    * <Function description>
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   14-09-2010
    */
    PROCEDURE add_status
    (
        i_lang                 IN LANGUAGE.id_language%TYPE,
        sc_id_workflow         IN wf_workflow.id_workflow%TYPE,
        sc_id_status           IN wf_status.id_status%TYPE,
        sc_id_software         IN software.id_software%TYPE,
        sc_id_institution      IN institution.id_institution%TYPE,
        sc_id_profile_template IN profile_template.id_profile_template%TYPE,
        sc_id_functionality    IN sys_functionality.id_functionality%TYPE,
        sc_id_category         IN category.id_category%TYPE,
        sc_icon                IN wf_status_config.icon%TYPE,
        sc_color               IN wf_status_config.color%TYPE,
        sc_rank                IN wf_status_config.rank%TYPE,
        sc_function            IN wf_status_config.FUNCTION%TYPE DEFAULT NULL,
        sc_flg_insert          IN wf_status_config.flg_insert%TYPE,
        sc_flg_update          IN wf_status_config.flg_update%TYPE,
        sc_flg_delete          IN wf_status_config.flg_delete%TYPE,
        sc_flg_read            IN wf_status_config.flg_read%TYPE,
        s_description          IN wf_status.description%TYPE DEFAULT NULL,
        s_icon                 IN wf_status.icon%TYPE DEFAULT NULL,
        s_color                IN wf_status.color%TYPE DEFAULT NULL,
        s_rank                 IN wf_status.rank%TYPE DEFAULT NULL,
        s_flg_available        IN wf_status.flg_available%TYPE DEFAULT 'Y',
        sw_description         IN wf_status_workflow.description%TYPE DEFAULT NULL,
        sw_flg_begin           IN wf_status_workflow.flg_begin%TYPE DEFAULT 'Y',
        sw_flg_final           IN wf_status_workflow.flg_final%TYPE DEFAULT 'Y',
        sw_flg_available       IN wf_status_workflow.flg_available%TYPE DEFAULT 'Y',
        print_translation_cod  IN BOOLEAN := FALSE
        
    );

    /**
    * <Function description>
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   14-09-2010
    */
    PROCEDURE add_transition
    (
        i_lang                 IN LANGUAGE.id_language%TYPE,
        tc_id_workflow         IN wf_workflow.id_workflow%TYPE,
        tc_id_status_begin     IN wf_status.id_status%TYPE,
        tc_id_status_end       IN wf_status.id_status%TYPE,
        tc_id_software         IN software.id_software%TYPE DEFAULT 0,
        tc_id_institution      IN institution.id_institution%TYPE DEFAULT 0,
        tc_id_profile_template IN profile_template.id_profile_template%TYPE DEFAULT 0,
        tc_id_functionality    IN sys_functionality.id_functionality%TYPE DEFAULT 0,
        tc_function            IN wf_transition_config.FUNCTION%TYPE DEFAULT NULL,
        tc_rank                IN wf_transition_config.rank%TYPE DEFAULT 10,
        tc_flg_permission      IN wf_transition_config.flg_permission%TYPE DEFAULT 'Y',
        tc_id_category         IN category.id_category%TYPE DEFAULT 0,
        t_flg_available        IN wf_transition.flg_available%TYPE DEFAULT 'Y',
        print_translation_cod  IN BOOLEAN := FALSE
    );

END pk_wf_referral;
/