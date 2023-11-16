/*-- Last Change Revision: $Rev: 2029002 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:13 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_sysconfig IS
    --

    SUBTYPE t_id_sys_config IS sys_config.id_sys_config%TYPE;
    SUBTYPE t_value IS sys_config.value%TYPE;
    SUBTYPE t_desc_sys_config IS sys_config.desc_sys_config%TYPE;
    SUBTYPE t_sc_row IS sys_config%ROWTYPE;
    FUNCTION get_desc_val
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN sys_config.id_institution%TYPE,
        i_id_sys_config  IN sys_config.id_sys_config%TYPE,
        i_val_sys_config IN sys_config.value%TYPE,
        i_id_software    IN sys_config.id_software%TYPE,
        i_fill_type      IN sys_config.fill_type%TYPE,
        i_mvalue         IN sys_config.mvalue%TYPE
    ) RETURN VARCHAR2;
    FUNCTION get_config
    (
        i_code_cf IN table_varchar,
        i_prof    IN profissional,
        o_msg_cf  OUT pk_types.cursor_type
    ) RETURN BOOLEAN;
    --
    FUNCTION get_config
    (
        i_code_cf IN sys_config.id_sys_config%TYPE,
        i_prof    IN profissional,
        o_msg_cf  OUT sys_config.value%TYPE
    ) RETURN BOOLEAN;

    FUNCTION get_config
    (
        i_code_cf IN sys_config.id_sys_config%TYPE,
        i_prof    IN profissional
    ) RETURN sys_config.value%TYPE;

    FUNCTION get_config
    (
        i_code_cf   IN sys_config.id_sys_config%TYPE,
        i_prof_inst IN institution.id_institution%TYPE,
        i_prof_soft IN software.id_software%TYPE
    ) RETURN sys_config.value%TYPE result_cache;
    --

    FUNCTION get_config
    (
        i_code_cf   IN sys_config.id_sys_config%TYPE,
        i_prof_inst IN institution.id_institution%TYPE,
        i_prof_soft IN software.id_software%TYPE,
        o_msg_cf    OUT sys_config.value%TYPE
    ) RETURN BOOLEAN;
    --

    /** @headcom
    * Public Function. Get all configurations available
    * 
    * @param      I_LANG                       Language ID
    * @param      I_ID_INSTITUTION             Institution ID
    * @param      I_SEARCH                     Search filter
    * @param      O_SYS_CONFIG                 Cursor with all configurations available
    * @param      O_ERROR                      Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2008/04/08
    */
    FUNCTION get_all_sys_config
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN sys_config.id_institution%TYPE,
        i_client         IN VARCHAR2,
        i_search         IN VARCHAR2,
        o_sys_config     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get configuration possible values
    *
    * @param      I_LANG                     Language ID
    * @param      I_ID_SYS_CONFIG            Configuration ID
    * @param      O_VALUES                   Configuration possible values
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2008/04/08
    */
    FUNCTION get_sys_config_values
    (
        i_lang          IN language.id_language%TYPE,
        i_id_sys_config IN sys_config.id_sys_config%TYPE,
        o_values        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get configuration information
    * 
    * @param      I_LANG                       Language ID
    * @param      I_ID_INSTITUTION             Institution ID
    * @param      I_ID_SYS_CONFIG              Configuration ID
    * @param      O_SYS_CONFIG                 Cursor with all configurations available
    * @param      O_ERROR                      Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2008/04/11
    */
    FUNCTION get_sys_config
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN sys_config.id_institution%TYPE,
        i_id_sys_config  IN sys_config.id_sys_config%TYPE,
        o_func_desc      OUT sys_config_translation.desc_functionality%TYPE,
        o_config_desc    OUT sys_config_translation.desc_config%TYPE,
        o_sys_config     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Update Value in SYS_CONFIG
    *
    * @param      I_LANG                               Language ID
    * @param      I_ID_SYS_CONFIG                      Configuration ID
    * @param      I_VALUE                              Configuration value
    * @param      O_ERROR                              Error 
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2008/04/08
    */
    FUNCTION set_sys_config
    (
        i_lang           IN language.id_language%TYPE,
        i_id_sys_config  IN sys_config.id_sys_config%TYPE,
        i_id_institution IN sys_config.id_institution%TYPE,
        i_id_software    IN table_number,
        i_value          IN table_varchar,
        i_fill_type      IN sys_config.fill_type%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_config
    (
        i_code_cf   IN table_varchar,
        i_prof_inst IN institution.id_institution%TYPE,
        i_prof_soft IN software.id_software%TYPE,
        o_msg_cf    OUT pk_types.cursor_type
    ) RETURN BOOLEAN;

    /**
    * This function returns the title of the configuration
    *
    * @param      I_LANG                               Language ID
    * @param      I_ID_SYS_CONFIG                      Configuration ID
    *
    * @return     varchar2 with title
    */
    FUNCTION get_desc_config
    (
        i_lang          IN language.id_language%TYPE,
        i_id_sys_config IN sys_config.id_sys_config%TYPE
    ) RETURN sys_config_translation.desc_config%TYPE;

    /**
    * This function returns the description of the configuration
    *
    * @param      I_LANG                               Language ID
    * @param      I_ID_SYS_CONFIG                      Configuration ID
    *
    * @return     varchar2 with description
    */
    FUNCTION get_desc_functionality
    (
        i_lang          IN language.id_language%TYPE,
        i_id_sys_config IN sys_config.id_sys_config%TYPE
    ) RETURN sys_config_translation.desc_functionality%TYPE;

    /** @headcom
    * Public Function. Get configuration information
    * 
    * @param      I_LANG                       Language ID
    * @param      I_ID_INSTITUTION             Institution ID
    * @param      I_ID_SYS_CONFIG              Configuration ID
    * @param      O_SYS_CONFIG                 Cursor with all configurations available
    * @param      O_ERROR                      Error
    * @param      o_impact_msg                 Impact message description
    * @param      o_impact_screen_msg          Impact message of a change in sys_config table, for a screen
    *
    * @return     boolean
    * @author     ARM
    * @version    0.1
    * @since      2008/11/18
    */

    FUNCTION get_sys_config
    (
        i_lang              IN language.id_language%TYPE,
        i_id_institution    IN sys_config.id_institution%TYPE,
        i_id_sys_config     IN sys_config.id_sys_config%TYPE,
        o_func_desc         OUT sys_config_translation.desc_functionality%TYPE,
        o_config_desc       OUT sys_config_translation.desc_config%TYPE,
        o_sys_config        OUT pk_types.cursor_type,
        o_error             OUT t_error_out,
        o_impact_msg        OUT sys_config_translation.impact_msg%TYPE,
        o_impact_screen_msg OUT sys_config_translation.impact_msg%TYPE
    ) RETURN BOOLEAN;

    /***************************************************************************************
    * Merges a record into sys_config_translation table                                    *
    *                                                                                      *
    * @param i_lang              record language                                           *     
    * @param i_sys_config        sys_config code                                           *
    * @param i_desc_config       description                                               *
    * @param i_desc_func         functionality description                                 *
    * @param i_impact_msg        configuration impact description title                    *
    * @param i_impact_screen_msg configuration impact description message                  *
    *                                                                                      *
    ***************************************************************************************/

    PROCEDURE insert_into_syscfg_translation
    (
        i_lang              IN language.id_language%TYPE,
        i_sys_config        IN sys_config_translation.id_sys_config%TYPE,
        i_desc_config       IN sys_config_translation.desc_config %TYPE,
        i_desc_func         IN sys_config_translation.desc_functionality%TYPE,
        i_impact_msg        IN sys_config_translation.impact_msg%TYPE,
        i_impact_screen_msg IN sys_config_translation.impact_screen_msg%TYPE
    );

    /***************************************************************************************
    * Merges a record into sys_config table                                                *
    *                                                                                      *
    * @param i_idsysconfig       sys_config code                                           *
    * @param i_value             sets the "value" field if not null                        *
    * @param i_market            market where the configuration is valid                   *
    * @param i_software          software where the configuration is valid                 *
    * @param i_desc              sets the "desc_sys_config" field if not null              *
    * @param i_fill_type         sets the "fill_type" field if not null                    *
    * @param i_client_config     sets the "client_configuration" field if not null         *
    * @param i_internal_config   sets the "internal_configuration" field if not null       *
    * @param i_global_config     sets the "global_configuration" field if not null         *
    * @param i_schema            sets the "flg_schema" field if not null                   *
    *                                                                                      *
    * @note  id_institution is set to 0                                                    *
    *                                                                                      *
    ***************************************************************************************/
    PROCEDURE insert_into_sysconfig
    (
        i_idsysconfig     IN sys_config.id_sys_config%TYPE,
        i_value           IN sys_config.value%TYPE,
        i_market          IN sys_config.id_market%TYPE,
        i_software        IN sys_config.id_software%TYPE,
        i_desc            IN sys_config.desc_sys_config%TYPE,
        i_fill_type       IN sys_config.fill_type%TYPE,
        i_client_config   IN sys_config.client_configuration%TYPE,
        i_internal_config IN sys_config.internal_configuration%TYPE,
        i_global_config   IN sys_config.global_configuration%TYPE,
        i_schema          IN sys_config.flg_schema%TYPE,
        i_mvalue          IN sys_config.mvalue%TYPE DEFAULT NULL
    );

    /***************************************************************************************
    * Merges a record into sys_config table                                                *
    *                                                                                      *
    * @param i_idsysconfig       sys_config code                                           *
    * @param i_value             sets the "value" field                                    *
    * @param i_institution       institution where the configuration is valid              *
    * @param i_software          software where the configuration is valid                 *
    * @param i_desc              sets the "desc_sys_config" field                          *
    * @param i_fill_type         sets the "fill_type" field                                *
    * @param i_client_config     sets the "client_configuration" field                     *
    * @param i_internal_config   sets the "internal_configuration" field                   *
    * @param i_global_config     sets the "global_configuration" field                     *
    * @param i_schema            sets the "flg_schema" field                               *
    *                                                                                      *
    * @note  id_market is set to the institution market                                    *
    *                                                                                      *
    ***************************************************************************************/
    PROCEDURE insert_into_sysconfig
    (
        i_idsysconfig     IN sys_config.id_sys_config%TYPE,
        i_value           IN sys_config.value%TYPE,
        i_institution     IN sys_config.id_institution%TYPE,
        i_software        IN sys_config.id_software%TYPE,
        i_desc            IN sys_config.desc_sys_config%TYPE,
        i_fill_type       IN sys_config.fill_type%TYPE,
        i_client_config   IN sys_config.client_configuration%TYPE,
        i_internal_config IN sys_config.internal_configuration%TYPE,
        i_global_config   IN sys_config.global_configuration%TYPE,
        i_schema          IN sys_config.flg_schema%TYPE,
        i_mvalue          IN sys_config.mvalue%TYPE DEFAULT NULL
    );
    /********************************************************************************************
    * Returns Number of records to display in each page
    *
    * @return                        Number of records
    *
    * @author                        RMGM
    * @since                         2011/06/15
    * @version                       2.6.1.1
    ********************************************************************************************/
    FUNCTION get_num_records RETURN NUMBER;
    /********************************************************************************************
    * Returns Number of Sys_config Records 
    *
    * @param i_lang                  Language id
    * @param i_id_institution        Institution identifier
    * @param i_client                Flag Client Configuration
    * @param i_search                Search
    * @param o_scf_out               SysConfig count
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Rui Gomes
    * @since                         2011/06/15
    * @version                       2.6.1.2
    ********************************************************************************************/
    FUNCTION get_all_sys_config_count
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_client         IN VARCHAR2,
        i_search         IN VARCHAR2,
        o_scf_out        OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns Sys_Config data from an specific Institution
    *
    * @param i_lang                  Language id
    * @param i_id_institution        Institution identifier
    * @param i_client                Flg Client Configuration
    * @param i_search                Search
    * @param i_start_record          Paging - initial recrod number
    * @param i_num_records           Paging - number of records to display
    *
    * @return                        table of SysConfig (t_table_sysconfig)
    *
    * @author                        Rui Gomes
    * @since                         2011/06/15
    * @version                       2.6.1.2
    ********************************************************************************************/
    FUNCTION get_all_sys_config_data
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN sys_config.id_institution%TYPE,
        i_client         IN VARCHAR2,
        i_search         IN VARCHAR2,
        i_start_record   IN NUMBER DEFAULT 1,
        i_num_records    IN NUMBER DEFAULT get_num_records,
        o_sysconfig_out  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /** @headcom
    * Public Function. Update Value in SYS_CONFIG when is in security or global administrator
    *
    * @param      I_LANG                               Language ID
    * @param      I_ID_SYS_CONFIG                      Configuration ID
    * @param      I_VALUE                              Configuration value
    * @param      O_ERROR                              Error 
    *
    * @return     boolean
    * @author     RMG
    * @version    0.1
    * @since      2013/11/06
    */
    FUNCTION set_sys_config_global
    (
        i_lang           IN language.id_language%TYPE,
        i_id_sys_config  IN sys_config.id_sys_config%TYPE,
        i_id_institution IN sys_config.id_institution%TYPE,
        i_id_software    IN table_number,
        i_value          IN table_varchar,
        i_fill_type      IN sys_config.fill_type%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    Method that returns list of values to sys_config multichoices
    **/
    FUNCTION get_sys_config_values
    (
        i_lang           IN language.id_language%TYPE,
        i_id_sys_config  IN sys_config.id_sys_config%TYPE,
        i_id_institution IN sys_config.id_institution%TYPE,
        i_id_software    IN sys_config.id_software%TYPE,
        o_values         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    g_error VARCHAR2(4000);

    PROCEDURE set_deprecated(i_id_sys_config IN VARCHAR2);
    PROCEDURE set_activated(i_id_sys_config IN VARCHAR2);

    PROCEDURE upd_desc_config
    (
        i_id_sys_config   IN VARCHAR2,
        i_desc_sys_config IN VARCHAR2
    );

    function get_data_access_inst return number;
	
END pk_sysconfig;
/
