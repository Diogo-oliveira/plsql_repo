/*-- Last Change Revision: $Rev: 2028671 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:14 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_edit_trail IS

    -- Public function and procedure declarations
    /**
    * This procedure sets the values for the audit columns. This is called by every audit triggers
    *
    * @param i_is_inserting          Boolean where TRUE means that an insert triggered the trigger
    * @param i_is_updating           Boolean where TRUE means that an update triggered the trigger
    *
    * @param io_create_user          User that created the record
    * @param io_create_institution   Institution where the record was created
    * @param io_create_time          Time and date when the record was created
    * @param io_update_user          User that last updated the record
    * @param io_update_institution   Institution where the record last updated
    * @param io_update_time          Time and date when the record last updated
    *
    * @author     Fábio Oliveira
    * @version    2.5.0.6
    * @since      2009/09/11
    * @notes
    */
    PROCEDURE set_audit_columns
    (
        i_is_inserting           IN BOOLEAN,
        i_is_updating            IN BOOLEAN,
        i_create_user_old        IN VARCHAR2 DEFAULT '',
        i_create_institution_old IN NUMBER DEFAULT NULL,
        i_create_time_old        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE),
        i_update_user_old        IN VARCHAR2 DEFAULT '',
        i_update_institution_old IN NUMBER DEFAULT NULL,
        i_update_time_old        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE),
        io_create_user           IN OUT VARCHAR2,
        io_create_institution    IN OUT NUMBER,
        io_create_time           IN OUT TIMESTAMP WITH LOCAL TIME ZONE,
        io_update_user           IN OUT VARCHAR2,
        io_update_institution    IN OUT NUMBER,
        io_update_time           IN OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

END pk_edit_trail;
/
