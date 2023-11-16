/*-- Last Change Revision: $Rev: 2027653 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:54 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY PK_SCALES_CONSTANT IS
    
    -- Private variable declarations
	
	/* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    
BEGIN
    

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END PK_SCALES_CONSTANT;
/