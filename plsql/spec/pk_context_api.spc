/*-- Last Change Revision: $Rev: 2028576 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:37 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_context_api AS
    PROCEDURE set_parameter
    (
        p_name  IN VARCHAR2,
        p_value IN VARCHAR2
    );

    PROCEDURE set_context_vars;

	PROCEDURE clear_all_parameters;
	
END pk_context_api;
/
