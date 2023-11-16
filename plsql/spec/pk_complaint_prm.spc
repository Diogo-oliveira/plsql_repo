/*-- Last Change Revision: $Rev:$*/
/*-- Last Change by: $Author:$*/
/*-- Date of last change: $Date:$*/

CREATE OR REPLACE PACKAGE pk_complaint_prm IS
    SUBTYPE t_clob IS CLOB;
    SUBTYPE t_big_char IS VARCHAR2(1000 CHAR);
    SUBTYPE t_med_char IS VARCHAR2(0200 CHAR);
    SUBTYPE t_low_char IS VARCHAR2(0030 CHAR);
    SUBTYPE t_flg_char IS VARCHAR2(0001 CHAR);

    /**
    *  Load of complaints
    *
    * @param i_lang                Prefered language ID
    * @param o_result_tbl          Number of records inserted
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     v2.8.2.0
    * @since                       2020/05/05
    */
    FUNCTION load_complaint
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Load of complaints' and triage board association
    *
    * @param i_lang                Prefered language ID
    * @param o_result_tbl          Number of records inserted
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     v2.8.2.0
    * @since                       2020/05/05
    */

    FUNCTION load_complaint_triage_board
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Load of complaints' alias
    *
    * @param i_lang                   Prefered language ID
    * @param o_result_tbl             Number of records inserted
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                         Adriana Salgueiro
    * @version                        v2.8.2.0
    * @since                          2020/10/07
    */

    FUNCTION load_complaint_alias
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Load of complaints' and codification association
    *
    * @param i_lang                   Prefered language ID
    * @param o_result_tbl             Number of records inserted
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                         Adriana Salgueiro
    * @version                        v2.8.2.0
    * @since                          2020/10/07
    */

    FUNCTION load_complaint_codification
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Insert context per complaint per dep_clin_serv
    *
    * @param i_lang                      Prefered language ID
    * @param i_institution               ID institutio
    * @param i_mkt                       ID market
    * @param i_vers                      Content version
    * @param i_software                  Id software
    * @param i_id_content                Id content complaint
    * @param i_clin_serv_in              Id clin serv in
    * @param i_clin_serv_out             Id clin serv out
    * @param i_dep_clin_serv_out         Id dep clin serv
    * @param o_result_tbl                Number of records inserted
    * @param o_error                     Error
    *
    * @return                            true or false on success or error
    *
    * @author                            Adriana Salgueiro
    * @version                           v2.8.2.0
    * @since                             2020/10/07
    */

    FUNCTION set_complaint_freq
    (
        i_lang              IN language.id_language%TYPE,
        i_institution       IN institution.id_institution%TYPE,
        i_mkt               IN table_number,
        i_vers              IN table_varchar,
        i_software          IN table_number,
        i_id_content        IN table_varchar DEFAULT table_varchar(),
        i_clin_serv_in      IN table_number,
        i_clin_serv_out     IN clinical_service.id_clinical_service%TYPE,
        i_dep_clin_serv_out IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_result_tbl        OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Insert complaint per sw and institution
    *
    * @param i_lang                        Prefered language ID
    * @param i_institution                 ID institutio
    * @param i_mkt                         ID market
    * @param i_vers                        Content version
    * @param i_software                    ID software
    * @param i_id_content                  ID content complaint
    * @param o_result_tbl                  Number of records inserted
    * @param o_error                       Error
    *
    * @return                              true or false on success or error
    *   
    * @author                              Adriana Salgueiro
    * @version                             v2.8.2.0
    * @since                               2020/10/07
    */

    FUNCTION set_complaint_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar DEFAULT table_varchar(),
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Clean complaint search
    *
    * @param i_lang                        Prefered language ID
    * @param i_institution                 ID institution
    * @param i_software                    ID software
    * @param o_result_tbl                  Number of records inserted
    * @param o_error                       Error
    *
    * @return                              true or false on success or error
    *   
    * @author                              Adriana Salgueiro
    * @version                             v2.8.2.0
    * @since                               2020/10/07
    */

    FUNCTION del_complaint_inst_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Clean complaint most frequent
    *
    * @param i_lang                        Prefered language ID
    * @param i_institution                 ID institution
    * @param i_software                    ID software
    * @param o_result_tbl                  Number of records inserted
    * @param o_error                       Error
    *
    * @return                              true or false on success or error
    *   
    * @author                              Adriana Salgueiro
    * @version                             v2.8.2.0
    * @since                               2020/10/07
    */

    FUNCTION del_complaint_freq
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

END pk_complaint_prm;
/
