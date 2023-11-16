/*-- Last Change Revision: $Rev: 1338305 $*/
/*-- Last Change by: $Author: sofia.mendes $*/
/*-- Date of last change: $Date: 2012-07-03 10:30:52 +0100 (ter, 03 jul 2012) $*/

CREATE OR REPLACE PACKAGE BODY pk_prog_notes_types IS

    -- Private type declarations
    
    -- Private constant declarations
    
    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations


BEGIN
    -- Initialization
   
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_prog_notes_types;
/