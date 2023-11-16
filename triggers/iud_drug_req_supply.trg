-- CHANGED BY:  Pedro Morais
-- CHANGE DATE: 18/02/2013 11:29
-- CHANGE REASON: [ALERT-251735] DROP unused objects
BEGIN
    EXECUTE IMMEDIATE 'DROP trigger iud_drug_req_supply';
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Already processed');
END;
-- CHANGE END:  Pedro Morais