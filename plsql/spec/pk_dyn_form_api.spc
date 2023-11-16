/*-- Last Change Revision: $Rev: 1936317 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2020-02-13 16:19:56 +0000 (qui, 13 fev 2020) $*/

CREATE OR REPLACE PACKAGE pk_dyn_form_api AS


    -- ****************************************
    FUNCTION get_dyn_cfg
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_patient        IN NUMBER,
        i_component_name IN VARCHAR2,
        i_action         IN NUMBER
    ) RETURN t_dyn_tree_table;

    FUNCTION get_dyn_cfg
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_patient    IN NUMBER,
        i_id_mkt_rel IN NUMBER,
        i_action     IN NUMBER
    ) RETURN t_dyn_tree_table;

END pk_dyn_form_api;
/
