CREATE OR REPLACE TYPE t_rec_cdr_related AS OBJECT
(
-- represents the rule related elements info
    product_id       VARCHAR2(1000 CHAR), --rule related product identifier
    related_id       VARCHAR2(1000 CHAR), --rule related element identifier
    related_type     VARCHAR2(1000 CHAR), --rule related element type
    related_supplier VARCHAR2(1000 CHAR), --rule related element supplier

    CONSTRUCTOR FUNCTION t_rec_cdr_related RETURN SELF AS RESULT
)
/
