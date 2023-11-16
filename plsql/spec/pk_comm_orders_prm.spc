/*-- Last Change Revision: $Rev: 1915044 $*/
/*-- Last Change by: $Author: humberto.cardoso $*/
/*-- Date of last change: $Date: 2019-09-04 17:07:52 +0100 (qua, 04 set 2019) $*/
CREATE OR REPLACE PACKAGE pk_comm_orders_prm IS

    FUNCTION set_comm_order_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_co_questionnaire_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

END pk_comm_orders_prm;
/
