/*-- Last Change Revision: $Rev: 2027296 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:47 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_java_session IS

    FUNCTION reset_packages RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   Reset do estado dos packages
           PARAMETROS:  Entrada:  
                        Saida:  
          
          CRIAÇÃO: RP 2007/09/03 
          NOTAS: 
        *********************************************************************************/
    BEGIN
        dbms_session.modify_package_state(dbms_session.reinitialize);
    
        pk_context_api.set_context_vars;
    
        RETURN TRUE;
    END;
END pk_java_session;
/
