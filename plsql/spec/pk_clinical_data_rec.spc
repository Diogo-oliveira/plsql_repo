/*-- Last Change Revision: $Rev: 2028562 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:31 +0100 (ter, 02 ago 2022) $*/
create or replace package PK_CLINICAL_DATA_REC is

  /**
  * Save clinical doc reconciliation info
  *
  * @param i_lang                   id language
  * @param i_prof                   professional, software and institution ids
  * @param i_id_clinica_data_rec    Clinical data reconciliation id
  * @param i_data                   Document data
  * @param o_error                  error message
  *
  * @return                    Return BOOLEAN
  *
  * @author        jorge.costa
  * @version       1
  * @since         27/05/2014
  */
  FUNCTION update_clinical_data_rec(i_lang                 IN NUMBER,
                                    i_id_professional      IN NUMBER,
                                    i_id_institution       IN NUMBER,
                                    i_id_software          IN NUMBER,
                                    i_id_clinical_data_rec IN NUMBER,
                                    i_data                 IN BLOB,
                                    o_error                OUT t_error_out)
    RETURN BOOLEAN;

  /**
  * Save clinical doc reconciliation info
  *
  * @param i_lang                   id language
  * @param i_prof                   professional, software and institution ids
  * @param i_id_clinica_data_rec    Clinical data reconciliation id
  * @param i_data                   Document data
  * @param o_error                  error message
  *
  * @return                    Return BOOLEAN
  *
  * @author        jorge.costa
  * @version       1
  * @since         27/05/2014
  */
  FUNCTION save_clinical_data_rec(i_lang                 IN NUMBER,
                                  i_id_professional      IN NUMBER,
                                  i_id_institution       IN NUMBER,
                                  i_id_software          IN NUMBER,
                                  i_id_clinical_data_rec IN number,
                                  i_data                 IN BLOB,
                                  o_error                OUT t_error_out)
    RETURN BOOLEAN;

  /**
  * Cancel clinical doc reconciliation 
  *
  * @param i_lang                   id language
  * @param i_prof                   professional, software and institution ids
  * @param i_id_clinica_data_rec    Clinical data reconciliation id
  * @param o_error                  error message
  *
  * @return                    Return BOOLEAN
  *
  * @author        jorge.costa
  * @version       1
  * @since         27/05/2014
  */
  FUNCTION delete_clinical_data_rec(i_lang                 IN NUMBER,
                                    i_id_professional      IN NUMBER,
                                    i_id_institution       IN NUMBER,
                                    i_id_software          IN NUMBER,
                                    i_id_clinical_data_rec IN number,
                                    o_error                OUT t_error_out)
    RETURN BOOLEAN;
		
  /**
  * Save clinical doc reconciliation info
  *
  * @param i_lang                   id language
  * @param i_prof                   professional, software and institution ids
  * @param i_id_clinica_data_rec    Clinical data reconciliation id
  * @param o_data                   Document data
  * @param o_error                  error message
  *
  * @return                    Return BOOLEAN
  *
  * @author        jorge.costa
  * @version       1
  * @since         27/05/2014
  */
  FUNCTION get_clinical_data_rec(i_lang                 IN NUMBER,
                                 i_id_professional      IN NUMBER,
                                 i_id_institution       IN NUMBER,
                                 i_id_software          IN NUMBER,
                                 i_id_clinical_data_rec IN NUMBER,
                                 o_data                 OUT BLOB,
                                 o_error                OUT t_error_out)
    RETURN BOOLEAN;

  /**
  * Get clinical doc reconciliation info
  *
  * @param i_lang                   id language
  * @param i_prof                   professional, software and institution ids
  * @param i_id_clinica_data_rec    Clinical data reconciliation id
  * @param o_data                   Document data
  * @param o_mime_type              Document mimy_type
  * @param o_error                  error message
  *
  * @return                    Return BOOLEAN
  *
  * @author        jorge.costa
  * @version       1
  * @since         27/05/2014
  */
  FUNCTION get_local_clinical_doc_info(i_lang                IN NUMBER,
                                       i_id_professional     IN NUMBER,
                                       i_id_institution      IN NUMBER,
                                       i_id_software         IN NUMBER,
                                       i_id_clinica_data_rec IN NUMBER,
                                       o_data                OUT BLOB,
                                       o_mime_type           OUT VARCHAR2,
                                       o_id_doc_external     OUT NUMBER,
                                       o_error               OUT t_error_out)
    RETURN BOOLEAN;

  /**
  * Start new clinicar data reconciliation. 
  * This function inserts a new entry on clinical_data_rec table 
  *
  * @param i_lang              id language
  * @param i_prof              professional, software and institution ids
  * @param i_doc_oid           document oid
  * @param i_doc_source        document source
  * @param o_newId             New clinical data reconciliation ID
  * @param o_error             error message
  *
  * @return                    Return BOOLEAN
  *
  * @author        jorge.costa
  * @version       1
  * @since         27/05/2014
  */
  FUNCTION start_clinical_data_rec(i_lang            IN NUMBER,
                                   i_id_professional IN NUMBER,
                                   i_id_institution  IN NUMBER,
                                   i_id_software     IN NUMBER,
                                   i_doc_oid         IN VARCHAR2,
                                   i_doc_source      IN VARCHAR2,
                                   o_newId           OUT NUMBER,
                                   o_error           OUT t_error_out)
    RETURN BOOLEAN;

end PK_CLINICAL_DATA_REC;
/
