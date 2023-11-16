/*-- Last Change Revision: $Rev: 1911342 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2019-08-06 11:26:32 +0100 (ter, 06 ago 2019) $*/

CREATE OR REPLACE PACKAGE pk_sys_list IS

    /*
    * Get list of values of a list group
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     Professional ID
    * @param   I_ID_SYS_LIST_GROUP        List group ID 
    * @param   o_sql                      list of vlues of a list group
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Rui Batista
    * @version 1.0
    * @since   29-JAN-2010
    *
    */
    FUNCTION get_sys_list_values
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sys_list_group IN sys_list_group.id_sys_list_group%TYPE,
        o_sql               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get list of values of a list group
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     Professional ID
    * @param   i_internal_name            List group internal name
    * @param   o_sql                      list of vlues of a list group
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Rui Batista
    * @version 1.0
    * @since   29-JAN-2010
    *
    */
    FUNCTION get_sys_list_values
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_internal_name IN sys_list_group.internal_name%TYPE,
        o_sql           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get list of values of a list group - INTERNAL
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     Professional ID
    * @param   I_ID_SYS_LIST_GROUP        List group ID 
    * @param   i_internal_name            List group internal name
    * @param   o_sql                      list of vlues of a list group
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Rui Batista
    * @version 1.0
    * @since   29-JAN-2010
    *
    */
    FUNCTION get_sys_list_values_int
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sys_list_group IN sys_list_group.id_sys_list_group%TYPE,
        i_internal_name     IN sys_list_group.internal_name%TYPE,
        o_sql               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get the description of a list value
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional ID
    * @param   I_ID_SYS_LIST        List Value ID to get the description
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Rui Batista
    * @version 1.0
    * @since   29-JAN-2010
    *
    */
    FUNCTION get_sys_list_value_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_sys_list IN sys_list.id_sys_list%TYPE
    ) RETURN VARCHAR2;
    --
    /*
    * Get the description of a context flag
    *
    * @param   i_lang                     language associated to the professional executing the request
    * @param   i_prof                     Professional ID
    * @param   i_grp_internal_name        Group internal name
    * @param   i_flg_context              Flag context
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Alexandre Santos
    * @version 1.0
    * @since   11-07-2012
    *
    */
    FUNCTION get_sys_list_value_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_grp_internal_name IN sys_list_group.internal_name%TYPE,
        i_flg_context       IN sys_list_group_rel.flg_context%TYPE
    ) RETURN pk_translation.t_desc_translation;
    --
    /*
    * Get id_sys_list of the given internal_name
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     Professional ID
    * @param   i_sys_list_group           Sys list group ID
    * @param   i_flg_context              Flag context
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Alexandre Santos
    * @version 1.0
    * @since   18-02-2010
    *
    */
    FUNCTION get_id_sys_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_sys_list_group IN sys_list_group_rel.id_sys_list_group%TYPE,
        i_flg_context    IN sys_list_group_rel.flg_context%TYPE
    ) RETURN sys_list_group_rel.id_sys_list%TYPE;
    --
    /*
    * Get id_sys_list of the given internal_name
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     Professional ID
    * @param   i_grp_internal_name        Group internal name
    * @param   i_flg_context              Flag context
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Alexandre Santos
    * @version 1.0
    * @since   18-02-2010
    *
    */
    FUNCTION get_id_sys_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_grp_internal_name IN sys_list_group.internal_name%TYPE,
        i_flg_context       IN sys_list_group_rel.flg_context%TYPE
    ) RETURN sys_list_group_rel.id_sys_list%TYPE;
    --
    /*
    * Get list of values of a list group
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     Professional ID
    * @param   I_ID_SYS_LIST_GROUP        List group ID 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Alexandre Santos
    * @version 1.0
    * @since   17-02-2010
    *
    */
    FUNCTION tf_sys_list_values
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sys_list_group IN sys_list_group.id_sys_list_group%TYPE
    ) RETURN t_table_sys_list;
    --
    /*
    * Get list of values of a list group
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     Professional ID
    * @param   i_internal_name            List group internal name
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Alexandre Santos
    * @version 1.0
    * @since   17-02-2010
    *
    */
    FUNCTION tf_sys_list_values
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_internal_name IN sys_list_group.internal_name%TYPE
    ) RETURN t_table_sys_list;
    --
    /*
    * Insert new group or update group description
    *
    * @param   i_sys_list_group           Primary key
    * @param   i_internal_name            List group internal name
    * @param   i_internal_desc            List group internal description
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Alexandre Santos
    * @version 1.0
    * @since   17-02-2010
    *
    */
    FUNCTION insert_into_sys_list_group
    (
        i_sys_list_group IN sys_list_group.id_sys_list_group%TYPE DEFAULT NULL,
        i_internal_name  IN sys_list_group.internal_name%TYPE,
        i_internal_desc  IN sys_list_group.internal_desc%TYPE DEFAULT NULL
    ) RETURN sys_list_group.id_sys_list_group%TYPE;
    --
    /*
    * Insert new list item and associate it to list group or update the translation/relation
    *
    * @param   i_lang                     language associated to the professional executing the request
    * @param   i_sys_list                 NULL when is a new list item; otherwise the id_sys_list to ins/upd language
    * @param   i_list_item_desc           List item description
    * @param   i_img_name                 Image name
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Alexandre Santos
    * @version 1.0
    * @since   18-02-2010
    *
    */
    FUNCTION insert_into_sys_list
    (
        i_lang           IN language.id_language%TYPE,
        i_sys_list       IN sys_list.id_sys_list%TYPE DEFAULT NULL,
        i_list_item_desc IN pk_translation.t_desc_translation,
        i_img_name       IN sys_list.img_name%TYPE DEFAULT NULL
    ) RETURN sys_list.id_sys_list%TYPE;
    --
    /*
    * Insert new list item and associate it to list group or update the translation/relation
    *
    * @param   i_lang                     language associated to the professional executing the request
    * @param   i_sys_list_group           Sys list group ID
    * @param   i_grp_internal_name        List group internal name
    * @param   i_market                   Market ID
    * @param   i_sys_list                 Sys list ID
    * @param   i_flg_available            Availability
    * @param   i_rank                     Rank
    * @param   i_inst                     Institution ID
    * @param   i_soft                     Software ID
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Alexandre Santos
    * @version 1.0
    * @since   18-02-2010
    *
    */
    PROCEDURE insert_into_sys_list_group_rel
    (
        i_lang              IN language.id_language%TYPE DEFAULT NULL,
        i_sys_list_group    IN sys_list_group_rel.id_sys_list_group%TYPE DEFAULT NULL,
        i_grp_internal_name IN sys_list_group.internal_name%TYPE DEFAULT NULL,
        i_market            IN sys_list_group_rel.id_market%TYPE,
        i_sys_list          IN sys_list_group_rel.id_sys_list%TYPE,
        i_flg_context       IN sys_list_group_rel.flg_context%TYPE,
        i_flg_available     IN sys_list_group_rel.flg_available%TYPE DEFAULT 'Y',
        i_rank              IN sys_list_group_rel.rank%TYPE DEFAULT 0,
        i_inst              IN institution.id_institution%TYPE DEFAULT 0,
        i_soft              IN software.id_software%TYPE DEFAULT 0
    );

    /*
    * Verify if a ID_SYS_LIST is included in the specific group.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional ID
    * @param   I_ID_SYS_LIST        List Value ID to get the description
    * @param   i_id_sys_list_group  List group ID
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Rui Batista
    * @version 1.0
    * @since   19-FEB-2010
    *
    */
    FUNCTION check_sys_list_in_group
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sys_list       IN sys_list.id_sys_list%TYPE,
        i_id_sys_list_group IN sys_list_group.id_sys_list_group%TYPE
    ) RETURN BOOLEAN;

    /*
    * Verify if a ID_SYS_LIST is included in the specific group and market.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional ID
    * @param   I_ID_SYS_LIST        List Value ID to get the description
    * @param   i_id_sys_list_group  List group ID
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Rui Batista
    * @version 1.0
    * @since   19-FEB-2010
    *
    */
    FUNCTION check_sys_list_in_group_market
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sys_list       IN sys_list.id_sys_list%TYPE,
        i_id_sys_list_group IN sys_list_group.id_sys_list_group%TYPE
    ) RETURN BOOLEAN;

    /*
    * Verify if a ID_SYS_LIST is included in the specific group, by market (optional).-INTERNAL
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional ID
    * @param   I_ID_SYS_LIST        List Value ID to get the description
    * @param   i_id_sys_list_group  List group ID
    * @param   i_flg_market         Search if the list value is available to the specific market
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Rui Batista
    * @version 1.0
    * @since   19-FEB-2010
    *
    */
    FUNCTION check_sys_list_in_group_int
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sys_list       IN sys_list.id_sys_list%TYPE,
        i_id_sys_list_group IN sys_list_group.id_sys_list_group%TYPE,
        i_flg_market        IN VARCHAR2
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get the flag context of a sys list in a sys list group
    *
    * @param        i_internal_name          Sys list group internal name
    * @param        i_sys_list               Sys listy id
    *
    * @return       The flag context
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        09-Jul-2010
    **********************************************************************************************/
    FUNCTION get_sys_list_context
    (
        i_internal_name IN sys_list_group.internal_name%TYPE,
        i_sys_list      IN sys_list_group_rel.id_sys_list%TYPE
    ) RETURN sys_list_group_rel.flg_context%TYPE;

    /**********************************************************************************************
    * Get the Id_Sys_List of a sys list given the internal_name
    *
    * @param        i_internal_name          Sys list group internal name
    *
    * @return       id_sys_list              id_sys_list matching the internal_name
    *
    * @author       Carlos Ferreira
    * @version      2.6.
    * @since        02-DEZ-2011
    **********************************************************************************************/
    FUNCTION get_id_sys_list(i_internal_name IN VARCHAR2) RETURN NUMBER;

    /*
    * Get list of values of a list group
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     Professional ID
    * @param   I_ID_SYS_LIST_GROUP        List group ID 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Alexandre Santos
    * @version 1.0
    * @since   17-02-2010
    *
    */
    FUNCTION tf_sys_list_values_int
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sys_list_group IN sys_list_group.id_sys_list_group%TYPE DEFAULT NULL,
        i_internal_name     IN sys_list_group.internal_name%TYPE DEFAULT NULL
    ) RETURN t_table_sys_list;

END pk_sys_list;
/
