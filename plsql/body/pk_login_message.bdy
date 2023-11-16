/*-- Last Change Revision: $Rev: 1789376 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2017-07-06 12:02:26 +0100 (qui, 06 jul 2017) $*/

CREATE OR REPLACE PACKAGE BODY ALERT.PK_LOGIN_MESSAGE IS

FUNCTION GET_MESSAGE(I_LANG IN NUMBER, I_CODE_MESS IN SYS_MESSAGE.CODE_MESSAGE%TYPE) RETURN VARCHAR2 IS
/******************************************************************************
   OBJECTIVO:   Retornar um texto de SYS_MESSAGE, quando se dá entrada do código
   				e da língua
   PARAMETROS:  Entrada: I_LANG - Língua
   						 I_CODE_MESS - Código da mensagem
    			Saida:

  CRIAÇÃO: CRS 2005/01/25
  NOTAS:
*********************************************************************************/

CURSOR C_MESSAGE IS
SELECT DESC_MESSAGE
  FROM SYS_MESSAGE
 WHERE CODE_MESSAGE=I_CODE_MESS
   AND ID_LANGUAGE = I_LANG
   AND FLG_AVAILABLE = 'Y';

L_MESS SYS_MESSAGE.DESC_MESSAGE%TYPE;

BEGIN
  OPEN C_MESSAGE;
  FETCH C_MESSAGE INTO L_MESS;
  CLOSE C_MESSAGE;

  RETURN L_MESS;

EXCEPTION
  WHEN OTHERS THEN
	RETURN NULL;
END;


/*
FUNCTION GET_MESSAGE(I_LANG IN NUMBER, I_CODE_MESS IN SYS_MESSAGE.CODE_MESSAGE%TYPE, O_DESC_MESS OUT SYS_MESSAGE.DESC_MESSAGE%TYPE) RETURN BOOLEAN IS
/******************************************************************************
   OBJECTIVO:   Retornar um texto de SYS_MESSAGE, quando se dá entrada do código
   				e da língua
   PARAMETROS:  Entrada: I_LANG - Língua
   						 I_CODE_MESS - Código da mensagem
    			Saida:   O_DESC_MESS - Descritivo da msg

  CRIAÇÃO: CRS 2005/01/25
  NOTAS:
*********************************************************************************/
/*
CURSOR C_MESSAGE IS
SELECT DESC_MESSAGE
  FROM SYS_MESSAGE
 WHERE CODE_MESSAGE=I_CODE_MESS
   AND ID_LANGUAGE = I_LANG
   AND FLG_AVAILABLE = 'Y';

BEGIN
  OPEN C_MESSAGE;
  FETCH C_MESSAGE INTO O_DESC_MESS;
  CLOSE C_MESSAGE;

  RETURN TRUE;

EXCEPTION
  WHEN OTHERS THEN
	RETURN FALSE;
END;
*/

FUNCTION GET_MESSAGE_ARRAY(I_LANG IN NUMBER, I_CODE_MSG_ARR IN ALERT.TABLE_VARCHAR, O_DESC_MSG_ARR OUT PK_TYPES.CURSOR_TYPE) RETURN BOOLEAN IS
/******************************************************************************
   OBJECTIVO:   Retornar um array de mensagens, correspondentes aos códigos
   				do array de entrada
   PARAMETROS:  Entrada: I_LANG - Língua em que deve ser transmitida a mensagem
   						 I_CODE_MESG_ARR - Array de códigos de mensagens
    			Saida:

  CRIAÇÃO: CRS 2005/01/26
  NOTAS:
*********************************************************************************/
	AUX VARCHAR2(4000);
BEGIN
	 FOR I IN 1 .. I_CODE_MSG_ARR.COUNT
      LOOP
          AUX:=AUX || '''' ||I_CODE_MSG_ARR(I) ||'''';
		  IF (I!=I_CODE_MSG_ARR.COUNT) THEN
		  	 AUX:=AUX || ',';
		  END IF;
      END LOOP;
	  AUX:='SELECT CODE_MESSAGE,DESC_MESSAGE FROM SYS_MESSAGE WHERE ID_LANGUAGE = '|| I_LANG ||
	  		' AND CODE_MESSAGE IN (' || AUX || ') AND FLG_AVAILABLE = ''Y''';
	  OPEN O_DESC_MSG_ARR FOR AUX;
	  RETURN TRUE;

EXCEPTION
  WHEN OTHERS THEN
    PK_TYPES.OPEN_MY_CURSOR(O_DESC_MSG_ARR);
	  RETURN FALSE;
END;


END;
/

