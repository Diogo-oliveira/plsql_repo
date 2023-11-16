/*-- Last Change Revision: $Rev: 2028694 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:22 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_family AS

    /******************************************************************************
    
      PURPOSE:  Family Functions
      CREATION: RdSN 2006/10/12
       
    ******************************************************************************/

    /** @headcom
        PURPOSE:   Family Grid
        PARAMETERS:  IN:  I_LANG - User Selected language 
                          I_ID_PAT - Patient ID
                          I_PROF - User
                     OUT: O_PAT_PROB - Return of the patient's problems
                          O_PAT - Return of the patient's info
                          O_EPIS - Return of the patient's episodes 
                          O_ERROR - Error 
        CREATION : RdSN 2006/10/13
        UPDATE : RdSN 2006/11/13
                Usage of patient family from PAT_FAMILY_MEMBER to PATIENT
                PAT_FAMILY_MEMBER is only updated now through PK_FAMILY.SET_FAMILY_RELAT_PAT       
        NOTES: 
    */
    FUNCTION get_family_grid
    (
        i_lang     IN language.id_language%TYPE,
        i_id_pat   IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        o_pat_prob OUT pk_types.cursor_type,
        o_pat      OUT pk_types.cursor_type,
        o_epis     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
     PURPOSE :   Possible Family Relationships filtering by gender
      PARAMETERS:  IN:  I_LANG - User Selected language 
            I_PROF - User
                            I_PATIENT - Patient ID
                    OUT:    O_FAMILY_RELAT - Return of the possible relationships
                            O_ERROR - Error 
      CREATION : RdSN 2006/10/13
          NOTES:       
    */
    FUNCTION get_family_relationships
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        o_family_relat OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
     PURPOSE :   Set Patient Family Relationships
      PARAMETERS:  IN:  I_LANG - User Selected language 
                I_ID_PATIENT - Patient ID
                            I_ID_PAT_RELATED - Related patient ID
                            I_ID_FAMILY_RELATIONSHIP - Family relationship ID between I_ID_PATIENT and I_ID_PAT_RELATED
            I_PROF - User
                    OUT:    O_ERROR - Error 
      CREATION : RdSN 2006/10/13 
          NOTES:       
    */

    FUNCTION set_family_relat_pat
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_patient             IN pat_family_member.id_patient%TYPE,
        i_id_pat_related         IN pat_family_member.id_pat_related%TYPE,
        i_id_family_relationship IN pat_family_member.id_family_relationship%TYPE,
        i_prof                   IN profissional,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
       OBJECTIVO:   Lista de epiódios Para o doente indicado. 
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional              
                 I_PATIENT- ID do paciente
                 I_PROF - D do profissional , instituição e software
              Saida:   O_GRID - Array de episódios de bloco operatório
                          O_ERROR - erro 
      
      CRIAÇÃO: RB 2006/08/28 
      NOTAS: RdSN Similar to PK_SR_VISIT but with no software filtering
          It is assumed that every episode has a corresponding record on the EPIS_INFO table
    */
    FUNCTION get_pat_episodes
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_pat     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
      PURPOSE :   Detect which patients have left the family I_ID_PAT_FAMILY 
            comparing the data from SINUS with the ones in ALERT 
                and erase the family reference on that patients
      PARAMETERS:  IN:  I_LANG - User Selected language 
                I_ID_PAT_FAMILY - Family ID
                            I_ID_PATIENT - Patients that belong to that family
            I_PROF - User
                    OUT:    O_ERROR - Error 
      CREATION : RdSN 2006/11/10
          NOTES: 
    */
    FUNCTION call_update_orphan_fam_mem
    (
        i_lang          IN language.id_language%TYPE,
        i_id_pat_family IN patient.id_pat_family%TYPE,
        i_id_patient    IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Detect which patients have left the family I_ID_PAT_FAMILY 
                       comparing the data from SINUS whith the ones in ALERT 
                       and erase the family reference on that patients
    *
    * Note: Esta é a função chamada pelo Flash.
    *
    * @param    i_lang           língua registada como preferência do profissional.
    * @param    i_id_pat_family  Family ID
    * @param    i_id_patient     Patients that belong to that family
    * @param    o_error          erro
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     ASM 
    * @version    0.1
    * @since      2007/07/26
    */
    FUNCTION update_orphan_fam_mem
    (
        i_lang          IN language.id_language%TYPE,
        i_id_pat_family IN patient.id_pat_family%TYPE,
        i_id_patient    IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_group_relationships
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_relationship_type IN relationship_type.id_relationship_type%TYPE,
        o_relationship      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_family_relationship_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_family_relationship IN family_relationship.id_family_relationship%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_family_relationship_id
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_family_relationship IN family_relationship.id_family_relationship%TYPE
    ) RETURN VARCHAR2;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_error VARCHAR2(4000);

    g_exception EXCEPTION;

END pk_family;
/
