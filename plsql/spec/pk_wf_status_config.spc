/*-- Last Change Revision: $Rev: 640250 $*/
/*-- Last Change by: $Author: filipe.sousa $*/
/*-- Date of last change: $Date: 2010-09-17 23:06:09 +0100 (sex, 17 set 2010) $*/

CREATE OR REPLACE PACKAGE pk_wf_status_config IS

    -- Author  : RICARDO.PATROCINIO
    -- Created : 14-09-2010 18:39:35
    -- Purpose : API for table wf_status_config

    -- Public type declarations
    --  type <TypeName> is <Datatype>;

    -- Public constant declarations
    -- <ConstantName> constant <Datatype> := <Value>;

    -- Public variable declarations
    -- <VariableName> <Datatype>;

    -- Public function and procedure declarations

    /**
    * Insert a record into table wf_status_config
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow identification
    * @param  I_ID_STATUS    Status identification
    * @param  I_ID_SOFTWARE    Software that can perform this action
    * @param  I_ID_INSTITUTION    Institution that can perform this action
    * @param  I_ID_PROFILE_TEMPLATE    Profile that can performe this action
    * @param  I_ID_FUNCTIONALITY    Functionality that can perform this action
    * @param  I_ICON    Status icon. Overrides WF_STATUS.ICON
    * @param  I_COLOR    Hexadecimal color code in the following format: GRID_BG_COLOR:GRID_FG_COLOR:OTHER_BG_COLOR:OTHER_FG_COLOR. For example: 0xC86464:0xFFFFFF:0xC86464:0xFFFFFF. Overrides WF_STATUS.COLOR
    * @param  I_RANK    Status rank. For ordering in status lists. Overrides WF_STATUS.RANK
    * @param  I_FUNCTION    This function returns status info based on other business rules
    * @param  I_FLG_INSERT    Y if has right to insert, N otherwise
    * @param  I_FLG_UPDATE    Y if has right to update, N otherwise
    * @param  I_FLG_DELETE    Y if has right to delete, N otherwise
    * @param  I_FLG_READ    Y if has right to read, N otherwise
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
        i_id_workflow         IN wf_status_config.id_workflow%TYPE,
        i_id_status           IN wf_status_config.id_status%TYPE,
        i_id_software         IN wf_status_config.id_software%TYPE,
        i_id_institution      IN wf_status_config.id_institution%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        i_icon                IN wf_status_config.icon%TYPE,
        i_color               IN wf_status_config.color%TYPE,
        i_rank                IN wf_status_config.rank%TYPE,
        i_function            IN wf_status_config.FUNCTION%TYPE,
        i_flg_insert          IN wf_status_config.flg_insert%TYPE,
        i_flg_update          IN wf_status_config.flg_update%TYPE,
        i_flg_delete          IN wf_status_config.flg_delete%TYPE,
        i_flg_read            IN wf_status_config.flg_read%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE,
        o_error               OUT t_error_out
    );

    /**
    * Update a record into table wf_status_config
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow identification
    * @param  I_ID_STATUS    Status identification
    * @param  I_ID_SOFTWARE    Software that can perform this action
    * @param  I_ID_INSTITUTION    Institution that can perform this action
    * @param  I_ID_PROFILE_TEMPLATE    Profile that can performe this action
    * @param  I_ID_FUNCTIONALITY    Functionality that can perform this action
    * @param  I_ICON    Status icon. Overrides WF_STATUS.ICON
    * @param  I_COLOR    Hexadecimal color code in the following format: GRID_BG_COLOR:GRID_FG_COLOR:OTHER_BG_COLOR:OTHER_FG_COLOR. For example: 0xC86464:0xFFFFFF:0xC86464:0xFFFFFF. Overrides WF_STATUS.COLOR
    * @param  I_RANK    Status rank. For ordering in status lists. Overrides WF_STATUS.RANK
    * @param  I_FUNCTION    This function returns status info based on other business rules
    * @param  I_FLG_INSERT    Y if has right to insert, N otherwise
    * @param  I_FLG_UPDATE    Y if has right to update, N otherwise
    * @param  I_FLG_DELETE    Y if has right to delete, N otherwise
    * @param  I_FLG_READ    Y if has right to read, N otherwise
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
        i_id_workflow         IN wf_status_config.id_workflow%TYPE,
        i_id_status           IN wf_status_config.id_status%TYPE,
        i_id_software         IN wf_status_config.id_software%TYPE,
        i_id_institution      IN wf_status_config.id_institution%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        i_icon                IN wf_status_config.icon%TYPE,
        i_color               IN wf_status_config.color%TYPE,
        i_rank                IN wf_status_config.rank%TYPE,
        i_function            IN wf_status_config.FUNCTION%TYPE,
        i_flg_insert          IN wf_status_config.flg_insert%TYPE,
        i_flg_update          IN wf_status_config.flg_update%TYPE,
        i_flg_delete          IN wf_status_config.flg_delete%TYPE,
        i_flg_read            IN wf_status_config.flg_read%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE,
        o_error               OUT t_error_out
    );

    /**
    * Insert a record into table wf_status_config, if record already exists updates it
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow identification
    * @param  I_ID_STATUS    Status identification
    * @param  I_ID_SOFTWARE    Software that can perform this action
    * @param  I_ID_INSTITUTION    Institution that can perform this action
    * @param  I_ID_PROFILE_TEMPLATE    Profile that can performe this action
    * @param  I_ID_FUNCTIONALITY    Functionality that can perform this action
    * @param  I_ICON    Status icon. Overrides WF_STATUS.ICON
    * @param  I_COLOR    Hexadecimal color code in the following format: GRID_BG_COLOR:GRID_FG_COLOR:OTHER_BG_COLOR:OTHER_FG_COLOR. For example: 0xC86464:0xFFFFFF:0xC86464:0xFFFFFF. Overrides WF_STATUS.COLOR
    * @param  I_RANK    Status rank. For ordering in status lists. Overrides WF_STATUS.RANK
    * @param  I_FUNCTION    This function returns status info based on other business rules
    * @param  I_FLG_INSERT    Y if has right to insert, N otherwise
    * @param  I_FLG_UPDATE    Y if has right to update, N otherwise
    * @param  I_FLG_DELETE    Y if has right to delete, N otherwise
    * @param  I_FLG_READ    Y if has right to read, N otherwise
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
        i_id_workflow         IN wf_status_config.id_workflow%TYPE,
        i_id_status           IN wf_status_config.id_status%TYPE,
        i_id_software         IN wf_status_config.id_software%TYPE,
        i_id_institution      IN wf_status_config.id_institution%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        i_icon                IN wf_status_config.icon%TYPE,
        i_color               IN wf_status_config.color%TYPE,
        i_rank                IN wf_status_config.rank%TYPE,
        i_function            IN wf_status_config.FUNCTION%TYPE,
        i_flg_insert          IN wf_status_config.flg_insert%TYPE,
        i_flg_update          IN wf_status_config.flg_update%TYPE,
        i_flg_delete          IN wf_status_config.flg_delete%TYPE,
        i_flg_read            IN wf_status_config.flg_read%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE,
        o_error               OUT t_error_out
    );

    /**
    * Get a record form table wf_status_config given the primary key)
    *
    * @param  I_ID_WORKFLOW    Workflow identification
    * @param  I_ID_STATUS    Status identification
    * @param  I_ID_SOFTWARE    Software that can perform this action
    * @param  I_ID_INSTITUTION    Institution that can perform this action
    * @param  I_ID_PROFILE_TEMPLATE    Profile that can performe this action
    * @param  I_ID_FUNCTIONALITY    Functionality that can perform this action
    * @param  I_ID_CATEGORY    Professional category identifier
    *
    * @RETURN  The wf_status_config record
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    FUNCTION get_rec
    (
        i_id_workflow         IN wf_status_config.id_workflow%TYPE,
        i_id_status           IN wf_status_config.id_status%TYPE,
        i_id_software         IN wf_status_config.id_software%TYPE,
        i_id_institution      IN wf_status_config.id_institution%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE
    ) RETURN wf_status_config%ROWTYPE;
END pk_wf_status_config;
/