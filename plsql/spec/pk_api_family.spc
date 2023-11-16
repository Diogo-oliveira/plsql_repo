/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_api_family IS

    -- Author  : Rui Spratley
    -- Created : 23-05-2008
    -- Purpose : API for INTER_ALERT

    /** @headcom
    * Public Function. Detect which patients have left the family I_ID_PAT_FAMILY 
                       comparing the data from SINUS whith the ones in ALERT 
                       and erase the family reference on that patients
    *
    * Note: Esta é a função chamada pelos Interfaces.
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
    FUNCTION intf_update_orphan_fam_mem
    (
        i_lang          IN language.id_language%TYPE,
        i_id_pat_family IN patient.id_pat_family%TYPE,
        i_id_patient    IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /* Stores log error messages. */
    g_error VARCHAR2(32000);
    /* Stores the package name. */
    g_package_name VARCHAR2(32);
    /* Message code for an unexpected exception. */
    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';

END pk_api_family;
/
