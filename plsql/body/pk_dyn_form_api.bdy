/*-- Last Change Revision: $Rev: 1936321 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2020-02-13 16:25:31 +0000 (qui, 13 fev 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_dyn_form_api AS


    -- ****************************************
    FUNCTION get_dyn_cfg
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_patient        IN NUMBER,
        i_component_name IN VARCHAR2,
        i_action         IN NUMBER
    ) RETURN t_dyn_tree_table is
	begin
	
        RETURN pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                       i_prof           => i_prof,
                                       i_patient        => i_patient,
                                       i_component_name => i_component_name,
                                       i_action         => i_action);
	
    END get_dyn_cfg;
	
    FUNCTION get_dyn_cfg
								(
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_patient    IN NUMBER,
        i_id_mkt_rel IN NUMBER,
        i_action     IN NUMBER
    ) RETURN t_dyn_tree_table IS
    BEGIN
        RETURN pk_dyn_form.get_dyn_cfg(i_lang       => i_lang,
                                       i_prof       => i_prof,
                                       i_patient    => i_patient,
                                       i_id_mkt_rel => i_id_mkt_rel,
                                       i_action     => i_action);
	end get_dyn_cfg;


END pk_dyn_form_api;
/
