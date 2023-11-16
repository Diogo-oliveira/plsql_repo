/*-- Last Change Revision: $Rev: 2028802 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:02 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_medication_types IS

    /*======================================
      --DRUG_PRESC_DET = DPD
    * ======================================*/

    
    SUBTYPE dpd_dpd_id_drug_presc_det_t IS drug_presc_det.id_drug_presc_det%TYPE;
    SUBTYPE pih_flg_type_presc_t IS prescription_instr_hist.flg_type_presc%TYPE;
    SUBTYPE pih_flg_subtype_presc_t IS prescription_instr_hist.flg_subtype_presc%TYPE;
    SUBTYPE pml_flg_status_t IS pat_medication_list.flg_status%TYPE;
    c_ddcs_flg_type_pesq_p						constant drug_dep_clin_serv.flg_type%type := 'P'; --pesquisaveis
    
END pk_medication_types;
/
