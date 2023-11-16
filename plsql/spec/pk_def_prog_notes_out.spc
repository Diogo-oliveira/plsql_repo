/*-- Last Change Revision: $Rev: 1330092 $*/
/*-- Last Change by: $Author: sofia.mendes $*/
/*-- Date of last change: $Date: 2012-06-20 11:40:42 +0100 (qua, 20 jun 2012) $*/

CREATE OR REPLACE PACKAGE pk_def_prog_notes_out IS

    -- Author  : SOFIA.MENDES
    -- Created : 6/11/2012 2:36:23 PM
    -- Purpose : API to be called by ALERT DEFAULT to update progress notes configs

    -- Public function and procedure declarations
    /**
    * Update the hidrics reference in the conf_button_block table
    * 
    * @author Sofia Mendes
    * @version 2.6.2
    * @since   11-Jun-2012
    */
    PROCEDURE update_button_hidrics_ref;

END pk_def_prog_notes_out;
/
