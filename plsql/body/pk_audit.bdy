/*-- Last Change Revision: $Rev: 2026756 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:48 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_audit AS

    FUNCTION OPEN(i_ip IN VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        INSERT INTO sys_entrance
            (id_sys_entrance,
             ip,
             action)
        VALUES
            (seq_sys_entrance.NEXTVAL,
             i_ip,
             'O');
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END;

    FUNCTION CLOSE(i_ip IN VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        INSERT INTO sys_entrance
            (id_sys_entrance,
             ip,
             action)
        VALUES
            (seq_sys_entrance.NEXTVAL,
             i_ip,
             'C');
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END;

    FUNCTION login
    (
        i_username IN VARCHAR2,
        i_ip       IN VARCHAR2,
        i_success  IN VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        INSERT INTO sys_login
            (id_sys_login,
             username,
             ip,
             success)
        VALUES
            (seq_sys_login.NEXTVAL,
             i_username,
             i_ip,
             i_success);
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END;

END pk_audit;
/
