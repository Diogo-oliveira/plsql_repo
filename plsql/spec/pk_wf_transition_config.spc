/*-- Last Change Revision: $Rev: 640250 $*/
/*-- Last Change by: $Author: filipe.sousa $*/
/*-- Date of last change: $Date: 2010-09-17 23:06:09 +0100 (sex, 17 set 2010) $*/

CREATE OR REPLACE PACKAGE pk_wf_transition_config IS

    -- Author  : RICARDO.PATROCINIO
    -- Created : 14-09-2010 18:38:10
    -- Purpose : API for table wf_transition_config

    -- Public type declarations
    --  type <TypeName> is <Datatype>;

    -- Public constant declarations
    -- <ConstantName> constant <Datatype> := <Value>;

    -- Public variable declarations
    -- <VariableName> <Datatype>;

    -- Public function and procedure declarations

    /**
    * Insert a record into table wf_transition_config
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow Id
    * @param  I_ID_STATUS_BEGIN    Starting status for transition
    * @param  I_ID_STATUS_END    Finish status for transition
    * @param  I_ID_SOFTWARE    Software that can perform this action
    * @param  I_ID_INSTITUTION    Institution that can perform this action
    * @param  I_ID_PROFILE_TEMPLATE    Profile that can performe this action
    * @param  I_ID_FUNCTIONALITY    Functionality that can perform this action
    * @param  I_FUNCTION    This function returns flg_permission for this transition availability
    * @param  I_RANK    Transition rank
    * @param  I_FLG_PERMISSION    A - if this transition is allowed for the software, institution, profile_template and functionality, D - otherwise
    * @param  I_ID_CATEGORY    Professional category identifier
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE ins_rec
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_id_workflow         IN wf_transition_config.id_workflow%TYPE,
        i_id_status_begin     IN wf_transition_config.id_status_begin%TYPE,
        i_id_status_end       IN wf_transition_config.id_status_end%TYPE,
        i_id_software         IN wf_transition_config.id_software%TYPE,
        i_id_institution      IN wf_transition_config.id_institution%TYPE,
        i_id_profile_template IN wf_transition_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_transition_config.id_functionality%TYPE,
        i_function            IN wf_transition_config.FUNCTION%TYPE,
        i_rank                IN wf_transition_config.rank%TYPE,
        i_flg_permission      IN wf_transition_config.flg_permission%TYPE,
        i_id_category         IN wf_transition_config.id_category%TYPE,
        o_error               OUT t_error_out
    );

    /**
    * Update a record into table wf_transition_config
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow Id
    * @param  I_ID_STATUS_BEGIN    Starting status for transition
    * @param  I_ID_STATUS_END    Finish status for transition
    * @param  I_ID_SOFTWARE    Software that can perform this action
    * @param  I_ID_INSTITUTION    Institution that can perform this action
    * @param  I_ID_PROFILE_TEMPLATE    Profile that can performe this action
    * @param  I_ID_FUNCTIONALITY    Functionality that can perform this action
    * @param  I_FUNCTION    This function returns flg_permission for this transition availability
    * @param  I_RANK    Transition rank
    * @param  I_FLG_PERMISSION    A - if this transition is allowed for the software, institution, profile_template and functionality, D - otherwise
    * @param  I_ID_CATEGORY    Professional category identifier
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE upd_rec
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_id_workflow         IN wf_transition_config.id_workflow%TYPE,
        i_id_status_begin     IN wf_transition_config.id_status_begin%TYPE,
        i_id_status_end       IN wf_transition_config.id_status_end%TYPE,
        i_id_software         IN wf_transition_config.id_software%TYPE,
        i_id_institution      IN wf_transition_config.id_institution%TYPE,
        i_id_profile_template IN wf_transition_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_transition_config.id_functionality%TYPE,
        i_function            IN wf_transition_config.FUNCTION%TYPE,
        i_rank                IN wf_transition_config.rank%TYPE,
        i_flg_permission      IN wf_transition_config.flg_permission%TYPE,
        i_id_category         IN wf_transition_config.id_category%TYPE,
        o_error               OUT t_error_out
    );

    /**
    * Insert a record into table wf_transition_config, if record already exists updates it
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow Id
    * @param  I_ID_STATUS_BEGIN    Starting status for transition
    * @param  I_ID_STATUS_END    Finish status for transition
    * @param  I_ID_SOFTWARE    Software that can perform this action
    * @param  I_ID_INSTITUTION    Institution that can perform this action
    * @param  I_ID_PROFILE_TEMPLATE    Profile that can performe this action
    * @param  I_ID_FUNCTIONALITY    Functionality that can perform this action
    * @param  I_FUNCTION    This function returns flg_permission for this transition availability
    * @param  I_RANK    Transition rank
    * @param  I_FLG_PERMISSION    A - if this transition is allowed for the software, institution, profile_template and functionality, D - otherwise
    * @param  I_ID_CATEGORY    Professional category identifier
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE merge_rec
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_id_workflow         IN wf_transition_config.id_workflow%TYPE,
        i_id_status_begin     IN wf_transition_config.id_status_begin%TYPE,
        i_id_status_end       IN wf_transition_config.id_status_end%TYPE,
        i_id_software         IN wf_transition_config.id_software%TYPE,
        i_id_institution      IN wf_transition_config.id_institution%TYPE,
        i_id_profile_template IN wf_transition_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_transition_config.id_functionality%TYPE,
        i_function            IN wf_transition_config.FUNCTION%TYPE,
        i_rank                IN wf_transition_config.rank%TYPE,
        i_flg_permission      IN wf_transition_config.flg_permission%TYPE,
        i_id_category         IN wf_transition_config.id_category%TYPE,
        o_error               OUT t_error_out
    );

    /**
    * Get a record form table wf_transition_config given the primary key)
    *
    * @param  I_ID_WORKFLOW    Workflow Id
    * @param  I_ID_STATUS_BEGIN    Starting status for transition
    * @param  I_ID_STATUS_END    Finish status for transition
    * @param  I_ID_SOFTWARE    Software that can perform this action
    * @param  I_ID_INSTITUTION    Institution that can perform this action
    * @param  I_ID_CATEGORY    Professional category identifier
    * @param  I_ID_PROFILE_TEMPLATE    Profile that can performe this action
    * @param  I_ID_FUNCTIONALITY    Functionality that can perform this action
    *
    * @RETURN  The wf_transition_config record
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    FUNCTION get_rec
    (
        i_id_workflow         IN wf_transition_config.id_workflow%TYPE,
        i_id_status_begin     IN wf_transition_config.id_status_begin%TYPE,
        i_id_status_end       IN wf_transition_config.id_status_end%TYPE,
        i_id_software         IN wf_transition_config.id_software%TYPE,
        i_id_institution      IN wf_transition_config.id_institution%TYPE,
        i_id_category         IN wf_transition_config.id_category%TYPE,
        i_id_profile_template IN wf_transition_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_transition_config.id_functionality%TYPE
    ) RETURN wf_transition_config%ROWTYPE;
END pk_wf_transition_config;
/