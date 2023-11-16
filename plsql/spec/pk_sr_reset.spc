/*-- Last Change Revision: $Rev: 2028985 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:08 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_sr_reset AS

    FUNCTION sr_act_schedule_date RETURN BOOLEAN;

    /******************************************************************************************************
       OBJECTIVO: Limpar informação de todos os episódios, passando as visitas para uma instituição dummy 
       PARAMETROS:  Entrada: I_SOFTWARE - ID da aplicação
                                    I_INSTITUTION - ID da instituição. 0 para todas
          Saída:   O_ERROR - erro
          
      CRIAÇÃO: RB 2006/11/15
      NOTAS: 
    ******************************************************************************************************/

    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_error        VARCHAR2(2000);
    g_sr_dept      INTEGER;
    g_found        BOOLEAN;

    g_instit_lixo  CONSTANT institution.id_institution%TYPE := 56;
    g_patient_lixo CONSTANT patient.id_patient%TYPE := 11954;
    g_sr_epis_type CONSTANT epis_type.id_epis_type%TYPE := 4;
    g_active       CONSTANT VARCHAR2(1) := 'A';
    g_available    CONSTANT VARCHAR2(1) := 'Y';
    g_status_req   CONSTANT VARCHAR2(1) := 'R';
    g_soft_oris    CONSTANT software.id_software%TYPE := 2;

END pk_sr_reset;
/
