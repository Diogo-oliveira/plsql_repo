/*-- Last Change Revision: $Rev: 1982174 $*/
/*-- Last Change by: $Author: adriana.salgueiro $*/
/*-- Date of last change: $Date: 2021-03-09 15:20:47 +0000 (ter, 09 mar 2021) $*/

CREATE OR REPLACE PACKAGE pk_periodicobservation_prm IS
    SUBTYPE t_clob IS CLOB;
    SUBTYPE t_big_char IS VARCHAR2(1000 CHAR);
    SUBTYPE t_med_char IS VARCHAR2(0200 CHAR);
    SUBTYPE t_low_char IS VARCHAR2(0030 CHAR);
    SUBTYPE t_flg_char IS VARCHAR2(0001 CHAR);
    /********************************************************************************************
    * Get Periodic observation parameters dest id
    *
    * @param i_lang                Prefered language ID
    * @param i_id_po_param         Periodic Obs Parameter ID
    * @param i_from                Flg that show the id request (D - DEFAULT, A - ALERT)
    *
    *
    * @return                      Destination DB equivalent id
    *
    * @author                      RMGM
    * @version                     2.5.2
    * @since                       2012/12/27
    ********************************************************************************************/
    FUNCTION get_dest_pop_id
    (
        i_lang        IN language.id_language%TYPE,
        i_id_po_param IN po_param.id_po_param%TYPE,
        i_from        IN VARCHAR2 DEFAULT 'D'
    ) RETURN NUMBER;
    /********************************************************************************************
    * Set Default Periodic observation parameters
    *
    * @param i_lang                Prefered language ID
    * @param i_flg_type            Type of parameter configured in default
    * @param i_parameter           Parameter id in default
    *
    *
    * @return                      Destination DB equivalent id
    *
    * @author                      RMGM
    * @version                     2.5.2
    * @since                       2012/12/27
    ********************************************************************************************/
    FUNCTION get_dest_parameter_map
    (
        i_lang      IN language.id_language%TYPE,
        i_flg_type  IN po_param.flg_type%TYPE,
        i_parameter IN po_param.id_parameter%TYPE
    ) RETURN NUMBER;
    -- content loader method signature
    /********************************************************************************************
    * Set Default Periodic observation parameters
    *
    * @param i_lang                Prefered language ID
    * @param o_result              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.5.2
    * @since                       2012/12/27
    ********************************************************************************************/
    FUNCTION set_def_poparam
    (
        i_lang   IN language.id_language%TYPE,
        o_result OUT NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Periodic observation parameters multichoice values
    *
    * @param i_lang                Prefered language ID
    * @param o_result              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.5.2
    * @since                       2012/12/28
    ********************************************************************************************/
    FUNCTION set_def_poparam_mc
    (
        i_lang   IN language.id_language%TYPE,
        o_result OUT NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Default Periodic observation parameters by institution health program
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             Content Version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_result              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.5.2
    * @since                       2012/12/27
    ********************************************************************************************/
    FUNCTION set_pop_hpg_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Default Periodic observation parameters by institution unit measure
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             Content Version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_result              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.5.2
    * @since                       2012/12/27
    ********************************************************************************************/
    FUNCTION set_pop_um_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION del_pop_um_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Default Periodic observation parameters ranks
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             Content Version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_result              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.5.2
    * @since                       2012/12/27
    ********************************************************************************************/
    FUNCTION set_pop_rk_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION del_pop_rk_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns xxxxxxxxxxxx
    *
    * @param i_lang                  Language id
    * @param i_id_professional       Professional identifier
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/08/18
    * @version                       2.6.1.x
    ********************************************************************************************/
    FUNCTION set_poparamwh_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    -- frequent loader method signature

    FUNCTION del_poparamwh_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Default Periodic observation Sets by institution (support for task type 101,7,10)
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             Content Version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_result              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.4.3
    * @since                       2014/12/29
    ********************************************************************************************/
    FUNCTION set_pop_sets_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION del_pop_sets_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Default Periodic observation parameters By clinical Service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             Content Version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Destination Clinical service ID
    * @param i_id_dep_clin_serv    Dep_clin_serv ID
    * @param i_base_cs_list        List of base search clinical_service ids
    * @param o_result              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.5.2
    * @since                       2012/12/27
    ********************************************************************************************/
    FUNCTION set_po_param_cs_freq
    (
        i_lang              IN language.id_language%TYPE,
        i_institution       IN institution.id_institution%TYPE,
        i_mkt               IN table_number,
        i_vers              IN table_varchar,
        i_id_software       IN table_number,
        i_id_content        IN table_varchar,
        i_clin_serv_in      IN table_number,
        i_clin_serv_out     IN clinical_service.id_clinical_service%TYPE,
        i_dep_clin_serv_out IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_result_tbl        OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION del_po_param_cs_freq
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    -- global vars
    g_error         t_big_char;
    g_flg_available t_flg_char;
    g_active        t_flg_char;
    g_version       t_low_char;
    g_func_name     t_med_char;

    g_array_size  NUMBER;
    g_array_size1 NUMBER;
END pk_periodicobservation_prm;
/
