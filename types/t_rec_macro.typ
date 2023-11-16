-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 29/01/2013
-- CHANGE REASON: [ALERT-250487] A physician suggested to add the option "Anamnesi Fisiologica" (or in (truncated)
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_rec_macro IS OBJECT
(
    id_doc_template           NUMBER(24), -- documentation template identifier
    id_doc_macro_version  NUMBER(24),
    desc_macro            VARCHAR2(1000 CHAR), -- documentation macro description
    id_doc_area           NUMBER(24), -- documentation area identifier,
    ID_DOC_MACRO          number(24),
    flg_status            VARCHAR2(1 CHAR)
)
';
end;
/

--CHANGE END: Sofia Mendes