-- CHANGED BY: Joana Madureira Barroso
-- CHANGE DATE: 24/09/2014 17:34
-- CHANGE REASON: [ALERT-296372] 
GRANT EXECUTE ON pk_tools TO alert_pharmacy_func;

--->pk_prof_utils|grant
GRANT EXECUTE ON pk_prof_utils TO alert_pharmacy_func;
-- CHANGE END: Joana Madureira Barroso


-- CHANGED BY: Alexis Nascimento
-- CHANGE DATE: 21/10/2014 09:22
-- CHANGE REASON: [ALERT-299060] When the pharmacist edits a prescription its automatically validated
GRANT EXECUTE ON pk_tools TO alert_product_tr;
-- CHANGE END: When the pharmacist edits a prescription its automatically validated


grant execute on alert.pk_tools to alert_core_tech;
