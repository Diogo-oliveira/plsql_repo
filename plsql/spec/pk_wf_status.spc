/*-- Last Change Revision: $Rev: 640250 $*/
/*-- Last Change by: $Author: filipe.sousa $*/
/*-- Date of last change: $Date: 2010-09-17 23:06:09 +0100 (sex, 17 set 2010) $*/

CREATE OR REPLACE PACKAGE pk_wf_status IS

    -- Author  : RICARDO.PATROCINIO
    -- Created : 14-09-2010 18:29:50
    -- Purpose : API for table wf_status

    -- Public type declarations
    --  type <TypeName> is <Datatype>;

    -- Public constant declarations
    -- <ConstantName> constant <Datatype> := <Value>;

    -- Public variable declarations
    -- <VariableName> <Datatype>;

    -- Public function and procedure declarations

    /**
    * Insert a record into table wf_status
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_STATUS    Status id
    * @param  I_DESCRIPTION    Full description of status meaning. For internal use
    * @param  I_ICON    Default status icon
    * @param  I_COLOR    Default hexadecimal color code in the following format: GRID_BG_COLOR:GRID_FG_COLOR:OTHER_BG_COLOR:OTHER_FG_COLOR. For example:        0xC86464:0xFFFFFF:0xC86464:0xFFFFFF
    * @param  I_RANK    Default status rank. For ordering in status lists
    * @param  I_CODE_STATUS    Default status name
    * @param  I_FLG_AVAILABLE    Y if available, N otherwise
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE ins_rec
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_id_status     IN wf_status.id_status%TYPE,
        i_description   IN wf_status.description%TYPE,
        i_icon          IN wf_status.icon%TYPE,
        i_color         IN wf_status.color%TYPE,
        i_rank          IN wf_status.rank%TYPE,
        i_code_status   IN wf_status.code_status%TYPE,
        i_flg_available IN wf_status.flg_available%TYPE,
        o_error         OUT t_error_out
    );

    /**
    * Update a record into table wf_status
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_STATUS    Status id
    * @param  I_DESCRIPTION    Full description of status meaning. For internal use
    * @param  I_ICON    Default status icon
    * @param  I_COLOR    Default hexadecimal color code in the following format: GRID_BG_COLOR:GRID_FG_COLOR:OTHER_BG_COLOR:OTHER_FG_COLOR. For example:        0xC86464:0xFFFFFF:0xC86464:0xFFFFFF
    * @param  I_RANK    Default status rank. For ordering in status lists
    * @param  I_CODE_STATUS    Default status name
    * @param  I_FLG_AVAILABLE    Y if available, N otherwise
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE upd_rec
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_id_status     IN wf_status.id_status%TYPE,
        i_description   IN wf_status.description%TYPE,
        i_icon          IN wf_status.icon%TYPE,
        i_color         IN wf_status.color%TYPE,
        i_rank          IN wf_status.rank%TYPE,
        i_code_status   IN wf_status.code_status%TYPE,
        i_flg_available IN wf_status.flg_available%TYPE,
        o_error         OUT t_error_out
    );

    /**
    * Insert a record into table wf_status, if record already exists updates it
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_STATUS    Status id
    * @param  I_DESCRIPTION    Full description of status meaning. For internal use
    * @param  I_ICON    Default status icon
    * @param  I_COLOR    Default hexadecimal color code in the following format: GRID_BG_COLOR:GRID_FG_COLOR:OTHER_BG_COLOR:OTHER_FG_COLOR. For example:         0xC86464:0xFFFFFF:0xC86464:0xFFFFFF
    * @param  I_RANK    Default status rank. For ordering in status lists
    * @param  I_CODE_STATUS    Default status name
    * @param  I_FLG_AVAILABLE    Y if available, N otherwise
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE merge_rec
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_id_status     IN wf_status.id_status%TYPE,
        i_description   IN wf_status.description%TYPE,
        i_icon          IN wf_status.icon%TYPE,
        i_color         IN wf_status.color%TYPE,
        i_rank          IN wf_status.rank%TYPE,
        i_code_status   IN wf_status.code_status%TYPE,
        i_flg_available IN wf_status.flg_available%TYPE,
        o_error         OUT t_error_out
    );

    /**
    * Get a record form table wf_status given the primary key)
    *
    * @param  I_ID_STATUS    Status id
    *
    * @RETURN  The wf_status record
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    FUNCTION get_rec(i_id_status IN wf_status.id_status%TYPE) RETURN wf_status%ROWTYPE;
END pk_wf_status;
/