/*-- Last Change Revision: $Rev: 1905867 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2019-06-14 15:04:51 +0100 (sex, 14 jun 2019) $*/

CREATE OR REPLACE PACKAGE pk_icnp_prm IS
    SUBTYPE t_clob IS CLOB;
    SUBTYPE t_big_char IS VARCHAR2(1000 CHAR);
    SUBTYPE t_med_char IS VARCHAR2(0200 CHAR);
    SUBTYPE t_low_char IS VARCHAR2(0030 CHAR);
    SUBTYPE t_flg_char IS VARCHAR2(0001 CHAR);

    -- content loader method signature
    -- searcheable loader method signature
    /********************************************************************************************
    * Set Default ICNP TASK COMPOSITION
    *
    * @param i_lang                Prefered language ID
    * @param o_result              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/01/16
    ********************************************************************************************/
    FUNCTION load_icnp_task_comp_def
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_software    IN table_number,
        o_result         OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set ICNP_COMPOSITION for a set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_result              Number of records loaded
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2013/01/11
    ********************************************************************************************/
    FUNCTION set_inst_icnp_composition
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_software    IN table_number,
        o_result         OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION del_inst_icnp_composition
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set ICNP_COMPOSITION_HIST for a set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_result              Number of records loaded
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2013/01/11
    ********************************************************************************************/
    FUNCTION set_inst_icnp_composition_hist
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_software    IN table_number,
        o_result         OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set ICNP_COMPOSITION_TERM for a set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_result              Number of records loaded
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2013/01/11
    ********************************************************************************************/
    FUNCTION set_inst_icnp_composition_term
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_software    IN table_number,
        o_result         OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set ICNP TASK COMPOSITION BY SOFTWARE AND specified institution.
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param o_inst_interv_drug    Cursor of default data
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/01/17
    ********************************************************************************************/
    FUNCTION set_inst_task_comp_search
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_software       IN table_number,
        o_result         OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION del_inst_task_comp_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION set_icnp_predefined_act_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION del_icnp_predefined_act_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_icnp_pa_hist_search
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
    * Set ICNP DEFAULT INSTRUCTIONS BY SOFTWARE, MARKET AND specified institution.
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_market              Market ID's
    * @param i_version             CONTENT version's
    * @param i_software            ALERT software modules
    * @param o_result_tbl          Number of records inserted
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.4.1
    * @since                       2014/07/02
    ********************************************************************************************/
    FUNCTION set_icnp_def_instructions_msi
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result      OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION del_icnp_def_instructions_msi
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    -- frequent loader method signature
    FUNCTION set_icnp_axis_freq
    (
        i_lang              IN language.id_language%TYPE,
        i_institution       IN institution.id_institution%TYPE,
        i_mkt               IN table_number,
        i_vers              IN table_varchar,
        i_software          IN table_number,
        i_clin_serv_in      IN table_number,
        i_clin_serv_out     IN clinical_service.id_clinical_service%TYPE,
        i_dep_clin_serv_out IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_result_tbl        OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION del_icnp_axis_freq
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_icnp_composition_freq
    (
        i_lang              IN language.id_language%TYPE,
        i_institution       IN institution.id_institution%TYPE,
        i_mkt               IN table_number,
        i_vers              IN table_varchar,
        i_software          IN table_number,
        i_clin_serv_in      IN table_number,
        i_clin_serv_out     IN clinical_service.id_clinical_service%TYPE,
        i_dep_clin_serv_out IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_result_tbl        OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION del_icnp_composition_freq
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
    g_no            t_flg_char;

    g_array_size  NUMBER;
    g_array_size1 NUMBER;
END pk_icnp_prm;
/
