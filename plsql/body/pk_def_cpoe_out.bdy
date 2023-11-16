/*-- Last Change Revision: $Rev: 2026937 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:29 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_def_cpoe_out IS

    -- Computerized Prescription Order Entry (CPOE) DEFAULT API database package (outgoing direction)

    -- logging variables
    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);
    --g_error       VARCHAR2(4000);

    /********************************************************************************************
    * set intake and output (hidric) references in cpoe_task_type table (to be executed only by DEFAULT)
    *
    * @author                                Carlos Loureiro
    * @since                                 12-JUN-2012
    ********************************************************************************************/
    PROCEDURE set_cpoe_hidric_references IS
    BEGIN
        -- call set_cpoe_hidric_references procedure
        pk_cpoe_db.set_cpoe_hidric_references;
    END set_cpoe_hidric_references;

/********************************************************************************************/
/********************************************************************************************/
/********************************************************************************************/

BEGIN
    -- log initialization
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(object_name => g_package_name);
END pk_def_cpoe_out;
/
