/*-- Last Change Revision: $Rev: 2056168 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2023-03-20 09:27:01 +0000 (seg, 20 mar 2023) $*/
CREATE OR REPLACE PACKAGE BODY pk_login_sysconfig IS

    k_lf CONSTANT VARCHAR2(0010 CHAR) := '''';

    /******************************************************************************
   OBJECTIVO:   Retornar um array de valores, correspondentes aos códigos 
   				do array de entrada 
   PARAMETROS:  Entrada: I_CODE_CF - Array de códigos 
    			Saida:	 O_MSG_CF - Array de valores 
	
   CRIAÇÃO: JD 2005/01/26 

  UTILIZADO EM:  

  NOTAS: 
    *********************************************************************************/
    FUNCTION get_config
    (
        i_code_cf IN table_varchar,
        o_msg_cf  OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
        aux VARCHAR2(1000);
    BEGIN
    
        FOR i IN 1 .. i_code_cf.count
        LOOP
        
            aux := aux || k_lf || i_code_cf(i) || k_lf;
            IF (i != i_code_cf.count)
            THEN
                aux := aux || ',';
            END IF;

  END LOOP; 
  
        aux := 'SELECT ID_SYS_CONFIG,VALUE FROM finger_db.SYS_CONFIG WHERE ID_SYS_CONFIG IN (' || aux || ')';
    
  OPEN O_MSG_CF FOR AUX;
  
  RETURN TRUE;

    EXCEPTION
  WHEN OTHERS THEN  
    RETURN FALSE;
    END get_config;

    /******************************************************************************
   OBJECTIVO:   Retornar um texto de SYS_CONFIG, quando se dá entrada do código 
   PARAMETROS:  Entrada: I_CODE_CF - Código do valor 
    			Saida:   O_MSG_CF - valor 
	
  CRIAÇÃO: JD 2005/01/25 
  UTILIZADO EM: 
  NOTAS: 
    *********************************************************************************/
    FUNCTION get_config
    (
        i_code_cf IN VARCHAR2,
        o_msg_cf  OUT VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
    
        o_msg_cf := get_config(i_code_cf => i_code_cf);

  RETURN TRUE;

    EXCEPTION
  WHEN OTHERS THEN  
    RETURN FALSE;
    END get_config;

    /******************************************************************************
   OBJECTIVO:   Retornar um texto de SYS_CONFIG, quando se dá entrada do código 
   PARAMETROS:  Entrada: I_CODE_CF - Código do valor 
    			Saida:   
	
  CRIAÇÃO: JD 2005/01/25 
  UTILIZADO EM: 
  NOTAS: 
    *********************************************************************************/
    FUNCTION get_config(i_code_cf IN VARCHAR2) RETURN VARCHAR2 IS
  L_CODE_CF SYS_CONFIG.VALUE%TYPE;
        tbl_value table_varchar;
    BEGIN
    
        SELECT s.value
          BULK COLLECT
          INTO tbl_value
          FROM finger_db.sys_config s
  WHERE ID_SYS_CONFIG = I_CODE_CF;
 
        IF tbl_value.count > 0
        THEN
            l_code_cf := tbl_value(1);
        END IF;
    
  RETURN L_CODE_CF;

    EXCEPTION
  WHEN OTHERS THEN  
    RETURN NULL;
    END get_config;

END pk_login_sysconfig;
