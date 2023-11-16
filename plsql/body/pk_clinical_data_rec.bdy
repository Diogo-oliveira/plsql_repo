/*-- Last Change Revision: $Rev: 2026873 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:15 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_clinical_data_rec IS

    -- Log variables
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_error VARCHAR2(2000);

    g_flg_active  VARCHAR2(1 CHAR) := 'A';
    g_flg_pending VARCHAR2(1 CHAR) := 'P';

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
    FUNCTION update_clinical_data_rec
    (
        i_lang                 IN NUMBER,
        i_id_professional      IN NUMBER,
        i_id_institution       IN NUMBER,
        i_id_software          IN NUMBER,
        i_id_clinical_data_rec IN NUMBER,
        i_data                 IN BLOB,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'Updating clinical data information';
        ts_clinical_data_rec.upd(id_clinical_data_rec_in => i_id_clinical_data_rec, clinical_data_in => i_data);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_error := t_error_out(SQLCODE, SQLERRM, g_error, NULL, NULL, NULL, NULL, NULL);
            pk_alertlog.log_error(text => g_error, object_name => g_package_name, owner => g_package_owner);
        
            RETURN FALSE;
    END update_clinical_data_rec;

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
    FUNCTION save_clinical_data_rec
    (
        i_lang                 IN NUMBER,
        i_id_professional      IN NUMBER,
        i_id_institution       IN NUMBER,
        i_id_software          IN NUMBER,
        i_id_clinical_data_rec IN NUMBER,
        i_data                 IN BLOB,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'Updating clinical data information';
        ts_clinical_data_rec.upd(id_clinical_data_rec_in => i_id_clinical_data_rec,
                                 clinical_data_in        => i_data,
                                 flg_status_in           => g_flg_active);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_error := t_error_out(SQLCODE, SQLERRM, g_error, NULL, NULL, NULL, NULL, NULL);
            pk_alertlog.log_error(text => g_error, object_name => g_package_name, owner => g_package_owner);
        
            RETURN FALSE;
    END save_clinical_data_rec;

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
    FUNCTION delete_clinical_data_rec
    (
        i_lang                 IN NUMBER,
        i_id_professional      IN NUMBER,
        i_id_institution       IN NUMBER,
        i_id_software          IN NUMBER,
        i_id_clinical_data_rec IN NUMBER,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        ts_clinical_data_rec.del(id_clinical_data_rec_in => i_id_clinical_data_rec);
    
        RETURN TRUE;
    END delete_clinical_data_rec;

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
    FUNCTION get_clinical_data_rec
    (
        i_lang                 IN NUMBER,
        i_id_professional      IN NUMBER,
        i_id_institution       IN NUMBER,
        i_id_software          IN NUMBER,
        i_id_clinical_data_rec IN NUMBER,
        o_data                 OUT BLOB,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        BEGIN
            g_error := 'Selecting information';
            SELECT cdr.clinical_data
              INTO o_data
              FROM clinical_data_rec cdr
             WHERE cdr.id_clinical_data_rec = i_id_clinical_data_rec;
        
            o_data := pk_tech_utils.set_empty_blob(o_data);
        
        EXCEPTION
            WHEN no_data_found THEN
                o_data := pk_tech_utils.set_empty_blob(o_data);
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_error := t_error_out(SQLCODE, SQLERRM, g_error, NULL, NULL, NULL, NULL, NULL);
            pk_alertlog.log_error(text => g_error, object_name => g_package_name, owner => g_package_owner);
        
            RETURN FALSE;
    END get_clinical_data_rec;

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
    FUNCTION get_local_clinical_doc_info
    (
        i_lang                IN NUMBER,
        i_id_professional     IN NUMBER,
        i_id_institution      IN NUMBER,
        i_id_software         IN NUMBER,
        i_id_clinica_data_rec IN NUMBER,
        o_data                OUT BLOB,
        o_mime_type           OUT VARCHAR2,
        o_id_doc_external     OUT NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'SELECTING DATA';
        BEGIN
            SELECT di.doc_img, di.mime_type, di.id_doc_external
              INTO o_data, o_mime_type, o_id_doc_external
              FROM doc_image di
             INNER JOIN clinical_data_rec cdr
                ON cdr.doc_oid = to_char(di.id_doc_image)
             WHERE cdr.id_clinical_data_rec = i_id_clinica_data_rec
               AND di.flg_status = 'A';
        
            o_data := pk_tech_utils.set_empty_blob(o_data);
        
        EXCEPTION
            WHEN no_data_found THEN
                o_data := pk_tech_utils.set_empty_blob(o_data);
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_error := t_error_out(SQLCODE, SQLERRM, g_error, NULL, NULL, NULL, NULL, NULL);
            pk_alertlog.log_error(text => g_error, object_name => g_package_name, owner => g_package_owner);
        
            RETURN FALSE;
    END get_local_clinical_doc_info;

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
    FUNCTION start_clinical_data_rec
    (
        i_lang            IN NUMBER,
        i_id_professional IN NUMBER,
        i_id_institution  IN NUMBER,
        i_id_software     IN NUMBER,
        i_doc_oid         IN VARCHAR2,
        i_doc_source      IN VARCHAR2,
        o_newid           OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_iddocexternal NUMBER(24) := NULL;
    BEGIN
        g_error := 'Creating Clinica Data Reconciliation regist';
        o_newid := seq_clinical_data_rec.nextval;
    
        ts_clinical_data_rec.ins(id_clinical_data_rec_in => o_newid,
                                 doc_oid_in              => i_doc_oid,
                                 doc_source_in           => i_doc_source,
                                 id_professional_in      => i_id_professional,
                                 id_institution_in       => i_id_institution,
                                 dt_operation_in         => current_timestamp,
                                 flg_status_in           => g_flg_pending);
    
        RETURN TRUE;
    END;

BEGIN
    -- Log init
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);

    pk_alertlog.log_init(owner => g_package_owner, object_name => g_package_name);
END pk_clinical_data_rec;
/
