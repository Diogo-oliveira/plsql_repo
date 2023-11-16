/*-- Last Change Revision: $Rev: 2027104 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:02 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_edit_trail IS

    -- Function and procedure implementations
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
    ) IS
        l_str1 VARCHAR2(50 CHAR);
        l_str2 NUMBER(24);
    BEGIN
        --if we are directly on the database log with oracle user
        --temporarily we will need to substr to 24 chars while all fields are no x2(50 char)
        l_str1 := substr(nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), USER), 1, 24);
        l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'),
                            '999999999999999999999999D999',
                            'NLS_NUMERIC_CHARACTERS = ''. ''');
    
        IF i_is_inserting
        THEN
            io_create_user        := l_str1;
            io_create_time        := current_timestamp;
            io_create_institution := l_str2;
            io_update_user        := '';
            io_update_time        := CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE);
            io_update_institution := NULL;
        
        ELSIF i_is_updating
        THEN
            IF i_create_user_old IS NOT NULL
               OR i_create_institution_old IS NOT NULL
               OR i_create_time_old != CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE)
            THEN
                io_create_user        := i_create_user_old;
                io_create_time        := i_create_time_old;
                io_create_institution := i_create_institution_old;
            END IF;
        
            io_update_user        := l_str1;
            io_update_time        := current_timestamp;
            io_update_institution := l_str2;
        
        END IF;
    
        RETURN;
    
    EXCEPTION
        WHEN OTHERS THEN
            alertlog.pk_alertlog.log_error('PK_EDIT_TRAIL.SET_AUDIT_COLUMNS' || '-' || SQLERRM);
            RETURN;
    END set_audit_columns;

BEGIN
    -- Initialization
    pk_alertlog.log_init(pk_alertlog.who_am_i);
END pk_edit_trail;
/
