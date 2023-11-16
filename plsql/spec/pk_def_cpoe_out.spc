/*-- Last Change Revision: $Rev: 2028593 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:43 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_def_cpoe_out IS

    -- Computerized Prescription Order Entry (CPOE) DEFAULT API database package (outgoing direction)

    /********************************************************************************************
    * set intake and output (hidric) references in cpoe_task_type table
    *
    * @author                                Carlos Loureiro
    * @since                                 12-JUN-2012
    ********************************************************************************************/
    PROCEDURE set_cpoe_hidric_references;

END pk_def_cpoe_out;
/
